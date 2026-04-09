# Assignment App

Production-style Flutter implementation of the assignment requirements with offline-first behavior, resilient networking, background sync, and a premium UI layer.

## 1) Executive Summary

This application delivers:

- Paginated **User List** fetched from ReqRes Collections API
- **Create User** flow with online POST + offline persistence fallback
- Automatic **background sync** for pending user records via Workmanager
- Paginated **Movie List** + **Movie Detail** using OMDb API
- Per-user **offline bookmarks** with relationship integrity
- Fault-tolerant networking using simulated flaky GET behavior + retry/backoff
- Theme system supporting **Light/Dark** modes from a custom palette

Core technology stack:

- State management: `provider`
- Dependency injection: `get_it`
- Networking: `http`
- Local storage: `drift` (SQLite)
- Offline sync trigger: `workmanager`
- Connectivity awareness: `connectivity_plus`
- Image caching: `cached_network_image`

---

## 2) Feature and Functionality Documentation

## 2.1 User List Screen

**Functional scope**

- Fetches remote users from ReqRes Collections API
- Displays:
  - First name
  - Last name
  - Avatar
- Supports infinite pagination
- Tapping any user navigates to Movie List screen with selected user context

**Endpoints used**

- `GET https://reqres.in/api/collections/demo/records?project_id=10659&page={page}&limit=10`

**Headers**

- `x-api-key: <key>`
- `X-Reqres-Env: prod`

**Behavior notes**

- Local users and remote users are shown as separate sections
- UI handles transient failures with non-blocking reconnecting state

## 2.2 Add User Functionality

**Functional scope**

- User can create a new user from dedicated form screen
- Input fields:
  - Name
  - Job (mapped to last name in ReqRes collection schema)

**Online behavior**

- Immediately POSTs user data to ReqRes Collections API
- Persists synced user in local SQLite store

**Offline behavior**

- Saves user locally with `pending` sync status
- Schedules sync when connectivity returns

**Endpoint used**

- `POST https://reqres.in/api/collections/demo/records?project_id=10659`

**Payload shape**

```json
{
  "data": {
    "avatar": "https://i.pravatar.cc/150?img=4",
    "firstName": "<name>",
    "lastName": "<job>"
  }
}
```

## 2.3 Offline and Background Sync

**Functional scope**

- Pending local users are synced in background
- Sync is triggered by:
  - App startup (eager sync)
  - Connectivity restore events
  - Workmanager job execution

**Data consistency behavior**

- Local sync status transitions: `pending -> synced` (or `failed` with retry path)
- User identity relationship is preserved for bookmarks tied to local user IDs

## 2.4 Movie List Screen

**Functional scope**

- Search-driven paginated movie list using OMDb
- Displays poster, title, year
- Infinite scroll pagination
- Tap on movie opens Movie Detail screen
- Bookmark/unbookmark directly from list

**Endpoint used**

- `GET https://www.omdbapi.com/?apikey=<key>&s={query}&page={page}`

## 2.5 Movie Detail Screen

**Functional scope**

- Fetches movie detail by IMDB ID
- Displays:
  - Title
  - Plot/description
  - Release date
  - Poster
- Bookmark/unbookmark from detail screen

**Endpoint used**

- `GET https://www.omdbapi.com/?apikey=<key>&i={imdbId}&plot=full`

## 2.6 Bookmarking (Offline First)

**Functional scope**

- Bookmarks are linked to a specific selected user
- Works fully offline
- Supports scenario: create user offline -> open movies -> bookmark immediately

**Storage behavior**

- Bookmarks persist in local SQLite and are queryable per user

## 2.7 Resilience and Error Handling

**Implemented mechanisms**

- Custom `FlakyHttpClient` randomly fails ~30% of GET requests
  - Simulated `SocketException` or HTTP `500`
- Exponential backoff retry for GET calls
- Non-blocking UI reconnecting indicators
- Silent retries to avoid crashy or intrusive UX

---

## 3) Architecture and Design

Codebase follows layered feature-based architecture:

- `lib/src/core`
  - `constants`: API constants/config
  - `db`: Drift database, schema, table access methods
  - `di`: service registration (`get_it`)
  - `network`: flaky client + retry logic
  - `sync`: background sync orchestration
  - `system`: connectivity + theme settings persistence
  - `theme`: color palette + theme configuration
- `lib/src/features`
  - `app`: global app-level controller
  - `users`: users API, repository, controllers, screens
  - `movies`: movies API, repository, controllers, screens

Design principles used:

- Separation of concerns
- Repository abstraction over data sources
- Controller-driven UI state
- Offline-first persistence strategy
- Dependency inversion through DI

---

## 4) Data Model Overview (SQLite / Drift)

Primary tables:

- `app_users`
  - local identity, optional remote identity, sync status, profile fields
- `movie_bookmarks`
  - bookmark records linked to `app_users.localId`
- `app_settings`
  - key/value app settings (theme mode, etc.)

Sync statuses:

- `pending`
- `synced`
- `failed`

---

## 5) API and Configuration

Configured in:

- `lib/src/core/constants/app_constants.dart`

Contains:

- OMDb API key
- ReqRes API key
- ReqRes environment and project ID
- Default movie search query

---

## 6) Build, Run, and Release

## 6.1 Install dependencies

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 6.2 Run (debug)

```bash
flutter run
```

## 6.3 Build Android release APK

```bash
flutter build apk --release
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`

## 6.4 Android release networking note

Release API calls require `INTERNET` permission in:

- `android/app/src/main/AndroidManifest.xml`

This is already configured.

---

## 7) Performance and Quality Notes

Implemented optimizations include:

- Deduplicated background sync scheduling
- Reduced unnecessary controller notifications in bookmark listeners
- Startup theme initialization before app bootstrap
- Cached image rendering
- Clean static analysis baseline (`flutter analyze`)

---

## 8) Assumptions and Constraints

- OMDb is used as assignment-approved alternative movie API.
- OMDb/ReqRes do not provide a native server-side bookmark endpoint.
  - Therefore, bookmark durability and relationship integrity are guaranteed locally.
  - User sync to server is handled via background process.

---

## 9) Test Checklist (Manual)

- User list loads and paginates
- Add user online -> appears synced
- Add user offline -> appears pending -> syncs when online
- Open movies from selected user
- Movie list paginates and opens detail
- Bookmark/unbookmark from list and detail
- App survives simulated flaky GET failures with reconnecting states
- Theme switching persists and applies correctly

---

## 10) Repository Conventions

- Keep API contracts in dedicated data source classes
- Keep UI widgets thin; business flow in controllers/repositories
- Prefer non-blocking UX for recoverable network failures
- Preserve offline-first behavior when extending features
