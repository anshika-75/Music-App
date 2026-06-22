# Backend Walkthrough - Music App

This document details the backend architecture, models, database schema, controllers, and caching logic of the **Music App** project.

---

## 1. Database Schema (PostgreSQL)

We created 4 database migrations using Rails ActiveRecord schema to establish a normalized database.

### Users Table
* Stores account credentials and role assignments.
* **Columns**:
  - `id` (Primary Key)
  - `email` (string, unique, index)
  - `password` (string, stores the bcrypt password digest)
  - `role` (string, values: `artist` or `listener`)
  - `created_at` / `updated_at` (timestamps)

### Artist Profiles Table
* Stores profile metadata for artists.
* **Columns**:
  - `id` (Primary Key)
  - `user_id` (foreign key pointing to `users`)
  - `name` (string)
  - `bio` (text)
  - `created_at` / `updated_at` (timestamps)

### Listener Profiles Table
* Stores profile metadata for listeners.
* **Columns**:
  - `id` (Primary Key)
  - `user_id` (foreign key pointing to `users`)
  - `name` (string)
  - `profile_photo` (string path to local photo)
  - `created_at` / `updated_at` (timestamps)

### Songs Table
* Stores uploaded song metadata.
* **Columns**:
  - `id` (Primary Key)
  - `artist_id` (foreign key referencing `users.id`)
  - `title` (string)
  - `genre` (string)
  - `description` (text)
  - `mp3_file_path` (string)
  - `created_at` / `updated_at` (timestamps)

---

## 2. Models & Associations

* **`User`** ([app/models/user.rb](file:///home/anshikagupta/Documents/Project/app/models/user.rb))
  - Associations: `has_one :artist_profile`, `has_one :listener_profile`, `has_many :songs` (using foreign key `artist_id`). All configured with `dependent: :destroy`.
  - Validations: email presence and uniqueness, password presence, role inclusion (`artist` or `listener`).
  - Custom password digest logic mapping to standard `password` column using `BCrypt::Password`.
* **`ArtistProfile`** ([app/models/artist_profile.rb](file:///home/anshikagupta/Documents/Project/app/models/artist_profile.rb))
  - Associations: `belongs_to :user`.
* **`ListenerProfile`** ([app/models/listener_profile.rb](file:///home/anshikagupta/Documents/Project/app/models/listener_profile.rb))
  - Associations: `belongs_to :user`.
  - Callback: `before_destroy :delete_profile_photo` to clean up physical avatar files from the disk when the profile is removed.
* **`Song`** ([app/models/song.rb](file:///home/anshikagupta/Documents/Project/app/models/song.rb))
  - Associations: `belongs_to :user` (foreign key `artist_id`).
  - Validations: title presence, mp3_file_path presence.
  - Callback: `before_destroy :delete_mp3_file` to remove the local MP3 file from the disk.

---

## 3. Session Authentication & Authorization

Implemented a simple cookie-based login/logout system using the Rails session cookie (`session[:user_id]`) in [SessionsController](file:///home/anshikagupta/Documents/Project/app/controllers/sessions_controller.rb).
* **Filters in `ApplicationController`**:
  - `current_user`: Loads the user matching `session[:user_id]`.
  - `require_login!`: Redirects to the login page if not logged in.
  - `require_artist!`: Ensures the current user has the `artist` role.
  - `require_listener!`: Ensures the current user has the `listener` role.

---

## 4. Controllers & Business Logic

* **`UsersController`** ([app/controllers/users_controller.rb](file:///home/anshikagupta/Documents/Project/app/controllers/users_controller.rb)): Handles registration (automatically generates the blank profile matching the selected user role) and account deletion.
* **`SongsController`** ([app/controllers/songs_controller.rb](file:///home/anshikagupta/Documents/Project/app/controllers/songs_controller.rb)): Handles artist CRUD. Restricts file types to `.mp3` only. Implements special update logic: if a new MP3 file is provided on edit, it treats it as a new upload, creating a new song record instead of editing the existing file path.
* **`ArtistProfilesController`** & **`ListenerProfilesController`**: Manage editing profile details and credentials.
* **`SearchController`** ([app/controllers/search_controller.rb](file:///home/anshikagupta/Documents/Project/app/controllers/search_controller.rb)): Joins the `songs` table with `artist_profiles` to query songs by name or artist name.

---

## 5. Redis Caching

Configured Redis as the cache store in [development.rb](file:///home/anshikagupta/Documents/Project/config/environments/development.rb).

1. **Artist Songs List Caching**: Caches the songs listing on the artist dashboard:
   ```ruby
   Rails.cache.fetch("artist_songs_#{current_user.id}") { ... }
   ```
   *Busted automatically when a song is created, updated, or deleted.*
2. **Search Query Caching**: Caches query results for listeners for 5 minutes:
   ```ruby
   Rails.cache.fetch("search_result_#{query}") { ... }
   ```
