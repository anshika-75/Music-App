# Music App (Part 1 - MVC Web App)

A modern, responsive Ruby on Rails MVC-based web application tailored for music creators (Artists) and music lovers (Listeners). This project is designed specifically to fulfill the requirements of **Part 1** of the training program.

It leverages **PostgreSQL** as the primary transactional database, **Redis** for performant caching, and **BCrypt** for secure account management, wrapped in a beautiful, custom-styled Glassmorphism Dark Theme.

---

## Tech Stack & Architecture
* **Language**: Ruby (v3.2.3)
* **Framework**: Ruby on Rails (v8.1.x)
* **Database**: PostgreSQL (Transactional data, tables configured with index optimizations and foreign keys)
* **Cache-Store**: Redis (Used to cache search queries and artist song lists)
* **Authentication**: Cookie-based Rails sessions with BCrypt hashed passwords
* **Styling**: Vanilla CSS with custom HSL variables, fluid typography (Outfit font), glassmorphism cards, custom audio components, and micro-animations.

---

## Features Implemented

### 👥 User Roles & Account Management
* Users can sign up as either an **Artist** or a **Listener**.
* Automatic creation of associated `ArtistProfile` or `ListenerProfile` tables upon signup.
* Account credentials (email, password) and profile details can be edited from the settings dashboard.
* Users can delete their account.
  * **Cascading Deletions:** Deleting an account triggers ActiveRecord callbacks to clean up physical storage:
    * Deleting an **Artist** deletes all their songs and removes the MP3 files from the disk.
    * Deleting a **Listener** deletes their profile and removes their uploaded avatar photo from the disk.

### 🎙️ Artist Features
* **Upload Music:** Upload audio tracks as `.mp3` files, along with title, genre, and description.
* **Music Dashboard:** View a list of all tracks uploaded by the artist.
* **Edit Details:** Update a song's metadata (title, genre, description).
  * *Upload Replacement Rule:* Changing the MP3 file itself is treated as publishing a new song, automatically generating a new record.
* **Delete Music:** Permanently delete a song and its physical file from the server.

### 🎧 Listener Features
* **Profile Setup:** Add/update a profile photo (stored locally in `/public/uploads/profiles`) and customize profile metadata.
* **Search Music:** Search for music by song title or artist name.
  * **Result Caching:** Search results are cached in Redis under query keys for 5 minutes.
  * **Playback:** Listen to the tracks directly inside the app using the inline audio player.

---

## Directory Layout
* **Controllers**: [app/controllers](file:///home/anshikagupta/Documents/Project/app/controllers) (Auth, CRUD, Caching, and Upload logic)
* **Models**: [app/models](file:///home/anshikagupta/Documents/Project/app/models) (ActiveRecord database models and validation rules)
* **Views & Templates**: [app/views](file:///home/anshikagupta/Documents/Project/app/views) (Clean MVC HTML layout templates)
* **Stylesheets**: [app/assets/stylesheets/application.css](file:///home/anshikagupta/Documents/Project/app/assets/stylesheets/application.css) (Glassmorphism dark theme)
* **Routes**: [config/routes.rb](file:///home/anshikagupta/Documents/Project/config/routes.rb) (RESTful resources mapping)
* **Tests/Specs**: [spec](file:///home/anshikagupta/Documents/Project/spec) (Unit tests for models and request/integration tests)

---

## Setup & Running Instructions

### 1. System Prerequisites
Ensure the following services are installed and running on your local machine:
* **Ruby** (v3.2.0 or higher)
* **PostgreSQL** (Active on default port `5432`)
* **Redis** (Active on default port `6379`)

### 2. Install Project Dependencies
Run `bundle install` using the local gem directory path:
```bash
bundle install
```

### 3. Setup the Database (PostgreSQL)
Create the database and execute the migrations:
```bash
bin/rails db:create db:migrate
```

### 4. Run the Test Suite (RSpec)
Validate the configuration and logic by executing the automated test suite:
```bash
# Using the local bundler path
/home/anshikagupta/.local/share/gem/ruby/3.2.0/bin/bundle exec rspec
```

### 5. Launch the Development Server
Boot the web server locally:
```bash
bin/rails server
```
Access the application by navigating to **`http://localhost:3000`** in your browser.
