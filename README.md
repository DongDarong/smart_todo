# Smart Todo ✅

Smart Todo is an offline-first, cross-platform todo application built with **Flutter** and **Dart**. It provides user authentication, local persistence, cloud sync, reminders, and powerful filtering—designed to work on mobile, web, and desktop platforms.

---

## Key Features ✨

- **User authentication** with Firebase (email/password).
- **Offline-first local storage** using SQLite (`sqflite`).
- **Cloud sync** with Firestore and timestamp-based merge/conflict resolution.
- **Task management**: add, edit, delete, set due date, set priority, toggle complete.
- **Filtering & search**: by status, date range, priority, and full-text search.
- **Local reminders** via `flutter_local_notifications` (scheduled notifications for due todos).
- **Statistics** view with totals and completion progress.
- **Theme switching** (light/dark) through `ThemeViewModel`.

---

## Architecture & Code Overview 🏗️

- `lib/main.dart` — App bootstrap: initializes Firebase and notifications, sets up `Provider` graph, and routes through `AuthWrapper`.
- `lib/data/models/todo_model.dart` — `TodoModel` and (de)serialization helpers.
- `lib/data/local/sqlite_service.dart` — Local DB CRUD and schema (`todos` table).
- `lib/data/remote/firebase_service.dart` — Firestore CRUD (collection `todos`).
- `lib/data/repository/todo_repository.dart` — Orchestrates local/remote operations, offline/online decisions, and `syncTodos` logic.
- `lib/viewmodels/` — `TodoViewModel` (business logic + notification scheduling), `AuthViewModel` (auth state), `ThemeViewModel` (theme management).
- `lib/core/notification_service.dart` — Local notification initialization and scheduling.
- `lib/views/` — UI pages: `auth` (login/register), `todo/home_page.dart`, `todo/statistics_page.dart`.

State management is handled with **Provider** + **ChangeNotifier**.

---

## Getting Started — Development Setup ⚙️

Prerequisites:

1. Flutter SDK (stable channel) installed and configured.
2. A Firebase project (for Auth & Firestore).

Quick start:

```bash
flutter pub get
flutter run
```

Building:

- Android APK: `flutter build apk --release`
- Web: `flutter build web`
- Windows: `flutter build windows`

### Firebase setup

1. Create a Firebase project at https://console.firebase.google.com/.
2. Enable **Email/Password** sign-in in Authentication.
3. Create a Firestore database (start in test mode for development).
4. Generate platform config with FlutterFire and place configs in `lib/firebase_options.dart` or run `flutterfire configure`.

> Note: If you already have `lib/firebase_options.dart`, ensure it matches your Firebase project.

### Local notifications

- Android requires manifest permission entries and a notification channel (already referenced in `lib/core/notification_service.dart`).
- iOS requires request for notification permissions and proper entitlements.

---

## Testing 🧪

- A basic widget test exists at `test/widget_test.dart`. Add unit tests for viewmodels, repository sync logic, and notification scheduling.

---

## Roadmap / Improvements 💡

- Add end-to-end tests and CI pipelines.
- Background sync and push notifications via FCM for cross-device reminders.
- Encrypt local DB for sensitive data.
- Add localization and accessibility improvements.

---

## Contributing 🤝

Contributions are welcome! Please open issues or PRs, add tests, and follow Flutter/Dart best practices. Consider adding a `CONTRIBUTING.md` and a license if you plan to accept external contributions.

---

## License

Add a license file (e.g., `LICENSE`) to make the project's licensing explicit.

---

Made with ❤️ using Flutter.

