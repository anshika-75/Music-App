# Frontend Walkthrough - Music App

This document details the user interface layout, typography, stylesheet configurations, page templates, and views of the **Music App** project.

---

## 1. CSS Design System

The application styling is written entirely in vanilla CSS inside [application.css](file:///home/anshikagupta/Documents/Project/app/assets/stylesheets/application.css).

* **Typography**: Imported **Outfit** via Google Fonts, fallback to system fonts.
* **Colors & Variables**: 
  - Vivid dark-mode background (`#0B0F19`) with custom radial gradients for a premium depth look.
  - HSL-driven violet/purple primary highlights (`#8B5CF6`) and emerald green success accents (`#10B981`).
  - Glassmorphic transparency panels (`rgba(30, 41, 59, 0.7)`) with fine borders (`rgba(255, 255, 255, 0.08)`) and high-blur backdrops.
* **Interactions**: Smooth micro-animations on form fields, hover transitions on buttons, list cards, and search items.

---

## 2. Global Layout & Layout Skeleton

* **Application Shell** ([app/views/layouts/application.html.erb](file:///home/anshikagupta/Documents/Project/app/views/layouts/application.html.erb)):
  - Includes a sticky navigation header with the **Music App** logo.
  - Dynamically renders session state: shows login/register buttons if signed out; displays user email, role badge (Artist vs Listener), dashboard/profile shortcuts, and logout button if signed in.
  - Implements uniform slide-in alerts for flash notifications (`notice` and `alert`).

---

## 3. View Templates

### Home & Session Login
* **[sessions/new.html.erb](file:///home/anshikagupta/Documents/Project/app/views/sessions/new.html.erb)**: Welcome landing page with sign-in fields and option to register.

### Account Registration
* **[users/new.html.erb](file:///home/anshikagupta/Documents/Project/app/views/users/new.html.erb)**: Registration form with email, password inputs, and user role select list (Artist vs Listener). Show error fields clearly if signup fails.

### Artist Dashboard & Operations
* **[songs/index.html.erb](file:///home/anshikagupta/Documents/Project/app/views/songs/index.html.erb)**: Artist dashboard split into a two-column grid. Left: Artist name, bio, email, and "Upload New Song" button. Right: List of uploaded songs showing titles, genres, and creation date, together with Edit/Delete options.
* **[songs/new.html.erb](file:///home/anshikagupta/Documents/Project/app/views/songs/new.html.erb)** & **[songs/edit.html.erb](file:///home/anshikagupta/Documents/Project/app/views/songs/edit.html.erb)**: Upload / Edit forms for songs. In the edit template, if an MP3 file is provided, a notice explains that saving will upload a new song record instead.
* **[artist_profiles/edit.html.erb](file:///home/anshikagupta/Documents/Project/app/views/artist_profiles/edit.html.erb)**: Allows updating artist details. Includes a separate "Delete Account" danger area at the bottom.

### Listener Dashboard & Search
* **[search/index.html.erb](file:///home/anshikagupta/Documents/Project/app/views/search/index.html.erb)**: Listener dashboard showing their avatar/photo (stored locally), name, and email, alongside the search music form.
* **[search/results.html.erb](file:///home/anshikagupta/Documents/Project/app/views/search/results.html.erb)**: Shows matching search results in a card format containing the song title, artist name, and a browser-native `<audio>` player / download link. Gracefully renders "No songs found" if there are no matches.
* **[listener_profiles/edit.html.erb](file:///home/anshikagupta/Documents/Project/app/views/listener_profiles/edit.html.erb)**: Updates name, credentials, and supports profile photo uploads. Includes the "Delete Account" button.
