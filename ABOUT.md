# About the Music App Codebase

This document explains the architecture of the **Music App**, how to read the code, and how the different directories and files interact.

---

## 1. Project Directory Structure
Here is an overview of what each key folder is used for:

```text
├── app/                      # Main application code (MVC pattern)
│   ├── assets/               # CSS stylesheets and images (UI visuals)
│   ├── controllers/          # The controllers (handles business logic and inputs)
│   │   ├── artist/           # Namespaced Artist controllers (songs, profile edits)
│   │   │   ├── profiles_controller.rb
│   │   │   └── songs_controller.rb
│   │   └── listener/         # Namespaced Listener controllers (searches, profile edits)
│   │       ├── profiles_controller.rb
│   │       └── searches_controller.rb
│   ├── models/               # The models (manages database queries, logic, and validations)
│   └── views/                # The views (HTML templates rendered in the browser)
│       ├── artist/           # Artist namespace view directories
│       │   ├── profiles/
│       │   └── songs/
│       └── listener/         # Listener namespace view directories
│           ├── profiles/
│           └── searches/
├── bin/                      # Executables and system scripts (e.g. rails, setup)
├── config/                   # Configuration files (routes, database settings, environment setups)
├── db/                       # Database schema and migration scripts
│   ├── migrate/              # Incremental SQL-like database migrations
│   └── schema.rb             # Generated snapshot of the active DB structure
├── public/                   # Static files, uploads, and media folders
│   └── uploads/              # Target folder for uploaded songs and profile photos
└── spec/                     # Automated RSpec tests (unit & integration/request tests)
```

---

## 2. The MVC Flow: Starting Point of a Request
When a user interacts with the app (e.g., clicks a link or submits a form), the request traverses the Rails stack in this sequence:

```text
  [Browser / Client]
         │
         ▼
 1. [config/routes.rb] ──────► Matches URL path to a namespaced controller action
         │
         ▼
 2. [app/controllers/...] ───► Runs logic (Artist:: or Listener::), performs auth, manages Redis cache
         ├─── interacts with
         ▼
 3. [app/models/...] ────────► Executes SQL queries, runs validators/callbacks on PostgreSQL
         │
         ▼
 4. [app/views/...] ─────────► Evaluates ERB tags from namespaced view folders
         │
         ▼
  [Browser / Client]
```

---

## 3. Key Operational Flows & Connections

### 🚪 Authentication Flow (Login / Registration)
How accounts are created, authenticated, and authorized:

1. **Signup Action:**
   * **Route:** `POST /users` maps to `UsersController#create`.
   * **Model Connection:** `UsersController` initializes a `User` model ([app/models/user.rb](file:///home/anshikagupta/Documents/Project/app/models/user.rb)).
   * **Custom BCrypt Hashing:** The `User` model intercepts the plain text password, hashes it using `BCrypt::Password`, and saves the hash into the `password` database column.
   * **Profile Association:** Depending on the selected role (`artist` or `listener`), the user model creates the corresponding `ArtistProfile` or `ListenerProfile` record in the database automatically.
   * **Redirection:** Redirects the user to `artist_songs_path` or `listener_search_path`.
2. **Login Action:**
   * **Route:** `POST /login` maps to `SessionsController#create`.
   * **Model Connection:** Looks up the `User` by email and calls `user.authenticate(password)`. If valid, stores the user's ID in `session[:user_id]`.
3. **Access Restrictions:**
   * [app/controllers/application_controller.rb](file:///home/anshikagupta/Documents/Project/app/controllers/application_controller.rb) implements filters (`require_artist!` and `require_listener!`) that check the current session. These filters block artists from accessing listener pages (like search) and vice versa.

---

### 🎙️ Artist Flow: Uploading & Managing Music
How songs are created, cached, and updated:

1. **Dashboard Listing:**
   * **Route:** `GET /artist/songs` maps to `Artist::SongsController#index`.
   * **Redis Caching:** The controller checks if the artist's song list is cached in Redis under the key `"artist_songs_#{current_user.id}"`. If yes, it loads from cache (saving database load). If not, it executes a database query and saves the result to Redis for 30 minutes.
   * **Rendering:** Renders the dashboard in [app/views/artist/songs/index.html.erb](file:///home/anshikagupta/Documents/Project/app/views/artist/songs/index.html.erb).
2. **Uploading Songs:**
   * **Route:** `POST /artist/songs` maps to `Artist::SongsController#create`.
   * **Validation:** Checks if the uploaded file is a valid `.mp3` extension.
   * **Disk Storage:** Stores the file on disk under `public/uploads/` with a unique UUID name.
   * **ActiveRecord Save:** Creates a `Song` record linking the title, genre, description, and file path.
   * **Cache Busting:** Clears the Redis cache key `"artist_songs_#{current_user.id}"` so the new track appears immediately on their dashboard.
3. **Song Updates (The Replacement Rule):**
   * **Route:** `PATCH /artist/songs/:id` maps to `Artist::SongsController#update`.
   * If only text metadata (title, genre) changes, it updates the record.
   * If a **new MP3 file** is uploaded, it leaves the old song untouched and creates a **brand new song record** (treated as publishing a new track), clearing the cache.

---

### 🎧 Listener Flow: Searching & Playback
How searching works with indexes and caches:

1. **Search Dashboard:**
   * **Route:** `GET /listener/search` maps to `Listener::SearchesController#index`.
   * **Rendering:** Shows the listener's profile details and a search input form inside [app/views/listener/searches/index.html.erb](file:///home/anshikagupta/Documents/Project/app/views/listener/searches/index.html.erb).
2. **Performing Search:**
   * **Route:** `GET /listener/search/results` maps to `Listener::SearchesController#results`.
   * **SQL Query (PostgreSQL):** Joins the `songs` table with `artist_profiles` and `users` to query records matching the query string against the song title, artist profile name, or user email:
     ```sql
     SELECT songs.*, artist_profiles.name AS artist_name 
     FROM songs 
     INNER JOIN users ON users.id = songs.artist_id 
     LEFT JOIN artist_profiles ON artist_profiles.user_id = songs.artist_id 
     WHERE songs.title ILIKE '%query%' OR artist_profiles.name ILIKE '%query%';
     ```
   * **Redis Caching:** Caches the search query result in Redis under `"search_result_#{query_string}"` for 5 minutes. Subsequent listeners searching for the same query will see results instantly.
   * **Rendering:** Displays matches inside [app/views/listener/searches/results.html.erb](file:///home/anshikagupta/Documents/Project/app/views/listener/searches/results.html.erb) with an inline browser audio player using `<audio src="<%= song.mp3_file_path %>">`.

---

### 🗑️ Cascading Accounts Deletion Flow
How data consistency is preserved during account removal:

1. **Trigger:**
   * **Route:** `DELETE /users/:id` maps to `UsersController#destroy`.
2. **ActiveRecord Cascade:**
   * The `User` model defines dependent associations:
     ```ruby
     has_one :artist_profile, dependent: :destroy
     has_one :listener_profile, dependent: :destroy
     has_many :songs, dependent: :destroy
     ```
   * Deleting the user triggers the destruction of these child models.
3. **File Cleanup Callbacks:**
   * Before the `Song` record is removed from the database, its `before_destroy :delete_mp3_file` callback runs, deleting the corresponding physical file from `public/uploads/` to prevent disk clutter.
   * Similarly, `ListenerProfile` invokes `before_destroy :delete_profile_photo` to delete the local profile picture.
