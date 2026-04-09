# Assignment App (Flutter)

Implements the provided Flutter assignment:

- Paginated **User List** from `reqres.in`
- **Create User** with **offline-first** support (persisted in SQLite via Drift)
- **Movie List** (paginated) + **Movie Detail** using **OMDb**
- **Offline Bookmarking** of movies, explicitly linked to a selected user (works fully offline)
- **Background sync** using **Workmanager** when connectivity returns
- **Network resilience**: 30% random GET failures + silent exponential-backoff retries + subtle “Reconnecting…” indicators
- **Provider** for state management, **get_it** for dependency injection
- **Light/Dark themes** implemented from the provided color palette, with a theme switcher

## APIs

- **Users (ReqRes)**: `https://reqres.in/api/users?page={page}`, `POST https://reqres.in/api/users`
- **Movies (OMDb)**:
  - Search: `https://www.omdbapi.com/?s={query}&page={page}&apikey=...`
  - Detail: `https://www.omdbapi.com/?i={imdbId}&apikey=...`

OMDb API key is configured in:

- `lib/src/core/constants/app_constants.dart` (`omdbApiKey`)

## Architecture / Folder structure

- `lib/src/core/`
  - `db/` Drift SQLite database + tables (users, bookmarks, settings)
  - `di/` get_it registrations
  - `network/` flaky interceptor + retry/backoff helper
  - `sync/` Workmanager dispatcher + sync service
  - `system/` connectivity + theme settings (stored in SQLite)
  - `theme/` light/dark Material 3 themes from palette
- `lib/src/features/`
  - `app/` app-level controller (theme mode)
  - `users/` reqres API + repository + screens/controllers
  - `movies/` omdb API + repository + screens/controllers

## Notes / Assumptions

- OMDb is used as the “Alternative Movie API” from the assignment (TMDB not required).
- The assignment asks to sync movie bookmarks “to the server”, but OMDb does not provide a bookmark-write API.
  - This app guarantees **no data loss** and **correct user↔bookmark relationships** offline.
  - On connectivity restoration, Workmanager runs a sync job that ensures pending local users are posted to ReqRes and local bookmarks are marked synced once the user has a remote id.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

# assignment_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
