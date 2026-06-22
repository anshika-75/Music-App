# Walkthrough - Music App (Part 1)

We have successfully generated and implemented the **Music App** Rails project, adhering strictly to the requirements. The codebase is clean, beginner-friendly, and fully functional.

We have separated the documentation guides for the Frontend and Backend components of the project in this folder.

---

## 📖 Walkthrough Guides

### 🎨 [Frontend Walkthrough (HTML / ERB / CSS Views)](./frontend_walkthrough.md)
This guide covers:
- Core dark-themed layout system in [application.css](../app/assets/stylesheets/application.css).
- User views for registration, login, and profile editing.
- Artist and Listener dashboards (including search form and native audio players).

### ⚙️ [Backend Walkthrough (Models / Controllers / Database / Cache)](./backend_walkthrough.md)
This guide covers:
- Normalized schema migrations (PostgreSQL database).
- ActiveRecord associations and custom security validations.
- Session authorization/authentication and helper filters.
- Songs and Search query caching using Redis cache.

---

## 🧪 Validation & Testing

We configured and executed automated RSpec tests covering all core behaviors, verifying model validations and request controllers (registration, login, song uploads, text updates, MP3 replacements, account deletions, and searches).

Run the test suite:
```bash
bundle exec rspec
```
**Results**: `28 examples, 0 failures` (All tests passed successfully).

---

## 🚀 How to Run Locally

1. **Verify Services**: Ensure PostgreSQL and Redis are running:
   ```bash
   sudo systemctl start postgresql
   sudo systemctl start redis-server
   ```
2. **Start Rails Server**:
   ```bash
   ./bin/rails server
   ```
3. **Open Browser**: Navigate to [http://localhost:3000](http://localhost:3000) to test out the features!
