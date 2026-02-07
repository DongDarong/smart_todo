# Memoro ✅

Memoro is an offline-first, cross-platform todo and note-taking application built with **Flutter** and **Dart**. It provides user authentication, local persistence, cloud sync, reminders, and powerful filtering—designed to work on mobile, web, and desktop platforms.

---

## Key Features ✨

- **User authentication** with Firebase (email/password).
- **Offline-first local storage** using SQLite (`sqflite`) with seamless cloud sync.
- **Cloud sync with conflict resolution** — timestamp-based merge (latest-write-wins), pending delete queue, bidirectional sync.
- **Auto-sync on connectivity return** — listens for network changes and syncs automatically when online.
  - **Task management**: add, edit, delete, set title, description, due date, priority, and reminders. Toggle complete/incomplete.
- **Scheduled reminders** with persistent notifications — reminders reschedule on app launch even after crashes.
- **Filtering & search**: by status, date range, priority, and full-text search.
- **Statistics** view with totals and completion progress.
- **Theme switching** (light/dark) through `ThemeViewModel`.
- **Cross-platform**: works on mobile (iOS/Android), web, and desktop (macOS/Windows/Linux).

---

## Architecture & Code Overview 🏗️

- `lib/main.dart` — App bootstrap: initializes Firebase and notifications, sets up `Provider` graph, and routes through `AuthWrapper`.
- `lib/data/models/todo_model.dart` — `TodoModel` with fields for title, description, priority, due date, reminder time, and sync status; includes serialization helpers.
- `lib/data/local/sqlite_service.dart` — Local DB (v4 schema) with CRUD operations, migration support for upgrades.
- `lib/data/local/pending_operations.dart` — Persists pending deletes (via `SharedPreferences`) for offline sync queuing.
- `lib/data/remote/firebase_service.dart` — Firestore CRUD operations on `users/{uid}/todos/{todoId}` collection.
- `lib/data/repository/todo_repository.dart` — Repository pattern:
  - Orchestrates local/remote operations based on online/offline state.
  - Implements **bidirectional sync** with **timestamp-based conflict resolution**: latest `updatedAt` wins on merge.
  - Processes pending deletes on sync.
  - Handles 4 merge scenarios: both exist, local-only, remote-only, both deleted.
- `lib/viewmodels/todo_viewmodel.dart` — Business logic + notification management:
  - `loadTodos()` + `_rescheduleReminders()` — Reschedules all active reminders on app start.
  - `addTodo()`, `editTodo()`, `deleteTodo()` — CRUD with integrated reminder lifecycle.
  - `startAutoSync(uid)`, `stopAutoSync()` — Listens to connectivity changes and syncs when online.
  - Proper cleanup in `dispose()`.
- `lib/core/notification_service.dart` — Local notification scheduling with timezone support:
  - `scheduleNotification()` — Schedule a reminder.
  - `cancelNotification(id)` — Cancel a specific reminder.
  - `cancelAllNotifications()` — Clear all reminders.
  - `getPendingNotifications()` — Query scheduled notifications.
- `lib/viewmodels/auth_viewmodel.dart` — Authentication state and user management.
- `lib/viewmodels/theme_viewmodel.dart` — Theme management (light/dark).
- `lib/views/` — UI pages: `auth/login_page.dart`, `auth/register_page.dart`, `todo/home_page.dart`, `todo/statistics_page.dart`.

**State management:** Provider + ChangeNotifier for viewmodels.

---

## Offline-First Sync & Conflict Resolution 🔄

The app uses a **repository pattern** with intelligent sync:

1. **Offline Operations**: All CRUD operations work offline — writes to local SQLite, reads from local cache.
2. **Online Sync**: When online, changes are pushed to Firestore immediately and synced back.
3. **Conflict Resolution**: On sync, todos with the latest `updatedAt` timestamp win.
4. **Pending Deletes**: Deletions performed offline are queued and applied remotely on sync.
5. **Auto-Sync**: Listens for connectivity changes and syncs automatically when online.

**Merge scenarios handled:**
- Both local and remote exist → latest `updatedAt` wins, synced copy marked as synced.
- Local-only, not synced → push to remote.
- Local-only, was synced → assume remote deleted it → delete local.
- Remote-only → pull into local.
- Pending deletes queue → applied at start of sync.

See [REMINDERS_GUIDE.md](REMINDERS_GUIDE.md) for detailed examples and architecture.

---

## Scheduled Reminders & Notifications 🔔

- **Create reminders**: Set `reminderTime` when adding/editing a todo.
- **Auto-reschedule on launch**: All active reminders (future times) are rescheduled when the app starts — survives app crashes.
- **Notification cancellation**: Deleting or editing a todo properly cancels/updates its notification.
- **Timezone support**: Uses device local timezone via `timezone` package.
- **Persistent storage**: Reminder times stored in SQLite and synced to Firestore.

Example usage in UI:
```dart
// Create with reminder
await todoViewModel.addTodo(
  'Meeting at 3 PM',
  uid,
  description: 'Discuss Q1 roadmap and priorities',
  reminderTime: DateTime.now().add(Duration(hours: 2)),
);

// Update reminder time
await todoViewModel.editTodo(
  todo,
  uid,
  newDescription: 'Updated: Include budget review',
  newReminderTime: DateTime.now().add(Duration(hours: 1)),
);

// Delete (auto-cancels notification)
await todoViewModel.deleteTodo(todo.id, uid);
```

---

## ViewModels & Integration 📱

### TodoViewModel Integration

After authentication, initialize sync and load todos:

```dart
// In your home/main screen initState:
@override
void initState() {
  super.initState();
  final uid = <get from auth>;
  final todoVM = Provider.of<TodoViewModel>(context, listen: false);
  
  // Load todos from local/remote
  todoVM.loadTodos(uid);
  
  // Start listening for connectivity changes & auto-sync
  todoVM.startAutoSync(uid);
}

@override
void dispose() {
  final todoVM = Provider.of<TodoViewModel>(context, listen: false);
  todoVM.stopAutoSync();
  super.dispose();
}
```

### Available Methods

- `loadTodos(String uid)` — Load todos, reschedule reminders.
- `addTodo(String title, String uid, {String? description, DateTime? dueDate, DateTime? reminderTime, int priority})` — Create todo with optional description and reminder.
- `editTodo(TodoModel todo, String uid, {String? newTitle, String? newDescription, DateTime? newDueDate, int? newPriority, DateTime? newReminderTime})` — Update todo properties including description and reminder.
- `toggleDone(TodoModel todo, String uid)` — Mark complete/incomplete.
- `deleteTodo(String id, String uid)` — Delete (cancels notification).
- `syncIfOnline(String uid)` — Manual sync trigger.
- `startAutoSync(String uid)` — Listen for connectivity and auto-sync.
- `stopAutoSync()` — Stop auto-sync listener.
- Filter methods: `setSearchQuery()`, `setStatusFilter()`, `togglePriorityFilter()`, `setDateRange()`, `clearFilters()`.
- Statistics: `totalTodos`, `completedCount`, `pendingCount`, `completionRate`.
- Smart categorization: `todayTodos`, `upcomingTodos`, `overdueTodos`, `completedTodos`.

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

> **Note**: See [REMINDERS_GUIDE.md](REMINDERS_GUIDE.md) for a detailed guide on using offline sync, conflict resolution, and scheduled reminders.

## Tools & CLI 🛠️

- **Flutter SDK** (stable) and **Dart SDK** — required to build and run the app.
- **FlutterFire CLI** (`flutterfire`) — helps configure Firebase platforms:
  ```bash
  dart pub global activate flutterfire_cli
  flutterfire configure
  ```
- Useful commands:
  - `flutter pub get` — install dependencies
  - `dart format .` — format code
  - `flutter analyze` — static analysis
  - `flutter run` — run on device/emulator
  - `flutter build apk --release` — build Android release APK

Ensure your PATH includes the pub cache binaries (e.g. `%USERPROFILE%\\.pub-cache\\bin`) so `flutterfire` is available.

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

- A basic widget test exists at `test/widget_test.dart`. 
- **Recommended test additions:**
  - Unit tests for `TodoRepository.syncTodos()` with various merge scenarios.
  - Unit tests for `NotificationService` scheduling and cancellation.
  - Widget tests for reminder editing UI flows.
  - Integration tests for offline → online transitions.
- Run tests: `flutter test`

---

## Roadmap / Improvements 💡

- [ ] Add comprehensive unit & integration tests for sync logic.
- [ ] Background sync via WorkManager for app-inactive periods.
- [ ] Push notifications via Firebase Cloud Messaging (FCM) for cross-device reminders.
- [ ] Recurring reminders (daily, weekly, monthly).
- [ ] Encrypt local SQLite DB for sensitive data.
- [ ] Snooze reminders from notification actions.
- [ ] Add localization and accessibility improvements.
- [ ] Backup/restore sync state to Firebase.

---

## Contributing 🤝

Contributions are welcome! Please open issues or PRs, add tests, and follow Flutter/Dart best practices. Consider adding a `CONTRIBUTING.md` and a license if you plan to accept external contributions.

---

## License

Add a license file (e.g., `LICENSE`) to make the project's licensing explicit.

---

Made with ❤️ using Flutter.

