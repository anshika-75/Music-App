# Project Workflow & Architecture Details

This document provides a comprehensive workflow and architectural overview of the **Music App**. It details every component from server boot, data routing, databases (PostgreSQL & Redis), caching policies, local storage, and callback triggers.

---

## 1. Complete Workflow Diagram

Below is the complete sequence diagram mapping how the system starts up, handles requests, saves files to local storage, saves paths in PostgreSQL, and caches items using Redis.

```mermaid
sequenceDiagram
    autonumber
    actor User as Artist/Listener
    participant Puma as Puma Web Server
    participant Router as Router (routes.rb)
    participant Ctrl as Controller Layer
    participant PG as PostgreSQL DB
    participant Cache as Redis Cache
    participant Disk as Local Disk (public/uploads)

    Note over Puma, Disk: [PHASE 1: SERVER BOOTUP]
    rect rgb(30, 41, 59)
        Puma->>Puma: Read config/puma.rb (thread/port bind)
        Puma->>Puma: Initialize Rails App via config.ru & config/environment.rb
        Puma->>PG: Establish pool connections (database.yml config)
        Puma->>Cache: Bind Cache Store connection to Redis (port 6379)
    end

    Note over User, Disk: [PHASE 2: HTTP REQUESTS FLOW]
    
    == Flow A: Artist Uploads Song ==
    User->>Router: POST /artist/songs (sends metadata & MP3 binary)
    Router->>Ctrl: Directs to Artist::SongsController#create
    Ctrl->>Ctrl: Authenticate & authorize (is_artist?)
    Ctrl->>Disk: File.open(path, 'wb') writes binary MP3 stream
    Disk-->>Ctrl: Returns relative path string ("/uploads/uuid.mp3")
    Ctrl->>PG: Save Song record (saves URL string path, not binary file)
    PG-->>Ctrl: Insertion confirmation (Record Saved)
    Ctrl->>Cache: Rails.cache.delete("artist_songs_{id}") [Busts cache]
    Ctrl-->>User: Redirect & Flash notice ("Song uploaded successfully")

    == Flow B: Listener Searches Music ==
    User->>Router: GET /listener/search/results?query=rock
    Router->>Ctrl: Directs to Listener::SearchesController#results
    Ctrl->>Ctrl: Authenticate & authorize (is_listener?)
    Ctrl->>Cache: Rails.cache.read("search_result_rock") [Check Redis cache]
    
    alt Cache Hit (Data present in Redis)
        Cache-->>Ctrl: Returns song list JSON (Bypasses PostgreSQL database)
    else Cache Miss (Data absent in Redis)
        Ctrl->>PG: Joins songs, users, profiles + ILIKE pattern query
        PG-->>Ctrl: Returns query matching array
        Ctrl->>Cache: Rails.cache.write("search_result_rock", query_data, expires_in: 5.min)
    end
    
    Ctrl-->>User: Renders results page with HTML audio tags (<audio src="/uploads/uuid.mp3">)
```

---

## 2. Server Startup Sequence (Puma to Rails)

When you run `bin/rails server`:
1. **Puma Booting:** Puma reads [config/puma.rb](file:///home/anshikagupta/Documents/Project/config/puma.rb). It initializes thread counts and binds to the specified port (default `3000`).
2. **Rack Environment Initialization:** Puma reads [config.ru](file:///home/anshikagupta/Documents/Project/config.ru), which calls `require_relative "config/environment"`.
3. **Bootstrapping dependencies:** `config/environment.rb` loads `config/boot.rb` to invoke `bundler/setup` which reads the `Gemfile` and loads all project dependencies.
4. **Rails Initialization:** `Rails.application.initialize!` boots up frameworks (ActiveRecord, ActiveSupport, ActionController).
5. **Database Handshake:** Active Record checks [config/database.yml](file:///home/anshikagupta/Documents/Project/config/database.yml) and connects to the PostgreSQL server.
6. **Cache Connection:** Active Support opens a socket connection to Redis based on the configurations inside [config/environments/development.rb](file:///home/anshikagupta/Documents/Project/config/environments/development.rb).

---

## 3. Database Layer (PostgreSQL vs Redis vs Local Storage)

The application separates its concerns dynamically into three storage zones to ensure fast operations and optimal memory footprint:

| Storage Type | Component | What is Stored | Purpose & Rationale |
| :--- | :--- | :--- | :--- |
| **PostgreSQL**<br>(Relational Database) | Database Tables (`users`, `songs`, etc.) | Emails, Password hashes (BCrypt), names, bios, and **relative string file paths** (`/uploads/uuid.mp3`). | Stores structured, transaction-safe relational data. It only holds file paths as strings because saving files directly inside database records (as blobs) degrades database read/write speeds. |
| **Local Disk**<br>(Server Filesystem) | Directory `/public/uploads/` | Physical `.mp3` audio files and `.jpg`/`.png` listener profile pictures. | Keeps static, heavy files on the local filesystem. This allows Puma/nginx to serve them directly via HTTP without consuming CPU processing cycles in database connections. |
| **Redis**<br>(In-Memory Key/Value) | Cache Store | Serialized search results arrays and cached dashboard lists. | Provides ultra-fast memory read lookups. Caching expensive database searches (SQL joins) or dashboard lists prevents CPU-heavy database queries on every page load. |

---

## 4. Key Request Flows & Code Connections

### 🚪 1. Routing Engine (`routes.rb`)
The router [config/routes.rb](file:///home/anshikagupta/Documents/Project/config/routes.rb) parses URL routes and translates them to controller commands.
* **Namespaces:** Grouping routes under `namespace :artist` and `namespace :listener` separates the controllers into distinct subfolders, meaning artist code and listener code remain physically isolated.
* **URL Resolution:** 
  * Entering `/artist/songs` maps to `Artist::SongsController#index`.
  * Entering `/listener/search` maps to `Listener::SearchesController#index`.

### 🎙️ 2. The Upload Flow (Local Storage + DB Link)
Located in [app/controllers/artist/songs_controller.rb](file:///home/anshikagupta/Documents/Project/app/controllers/artist/songs_controller.rb):
1. The user uploads a file through a HTML form: `f.file_field :mp3_file`.
2. The controller's `upload_mp3` method writes the binary stream to disk:
   * Saves it to `public/uploads/` directory.
   * Generates a unique UUID (e.g. `d3b07384.mp3`) to prevent overriding files with identical names.
3. Once the file is written, the database creates a row in the `songs` table setting the `mp3_file_path` column to `"/uploads/d3b07384.mp3"`.

### ⚡ 3. The Search & Caching Flow (Redis)
Located in [app/controllers/listener/searches_controller.rb](file:///home/anshikagupta/Documents/Project/app/controllers/listener/searches_controller.rb):
1. The listener inputs a search query (e.g. "Rock").
2. The application checks the Redis cache:
   ```ruby
   Rails.cache.fetch("search_result_rock", expires_in: 5.minutes)
   ```
3. **If cached:** Redis returns the matching results instantly.
4. **If not cached:** ActiveRecord joins the tables in PostgreSQL:
   ```sql
   SELECT songs.*, artist_profiles.name AS artist_name FROM songs ... WHERE title ILIKE '%rock%';
   ```
   The result is compiled, cached in Redis under `search_result_rock` for 5 minutes, and then displayed.

### 🗑️ 4. Account Deletion & Physical Cleanup (Callbacks)
To prevent orphaned files from filling up disk space:
* When an account is deleted, it triggers ActiveRecord cascading deletions (`dependent: :destroy`) defined in [app/models/user.rb](file:///home/anshikagupta/Documents/Project/app/models/user.rb).
* When a `Song` or `ListenerProfile` is destroyed, its model callback executes:
  * In [app/models/song.rb](file:///home/anshikagupta/Documents/Project/app/models/song.rb): `before_destroy :delete_mp3_file` runs, deleting the corresponding physical file from `public/uploads/` using `File.delete(path)`.
  * In [app/models/listener_profile.rb](file:///home/anshikagupta/Documents/Project/app/models/listener_profile.rb): `before_destroy :delete_profile_photo` deletes the user's avatar.
