# Scheduled Reminders Feature Guide

## Overview
The Smart Todo app now has a complete scheduled reminders system with persistent notifications, automatic reschedule on app launch, and conflict-free updates when editing/deleting todos.

## Features

### 1. **Schedule Reminders**
Set a reminder time when creating or editing a todo. The app will show a notification at the specified time.

```dart
// Create a todo with a reminder
await todoViewModel.addTodo(
  'Buy groceries',
  uid,
  reminderTime: DateTime.now().add(Duration(hours: 2)),
  dueDate: DateTime.now().add(Duration(days: 1)),
  priority: 3,
);
```

### 2. **Edit Reminders**
Update reminder times without losing the todo. Old reminders are automatically cancelled.

```dart
// Edit with a new reminder time
await todoViewModel.editTodo(
  existingTodo,
  uid,
  newTitle: 'Buy groceries and household items',
  newReminderTime: DateTime.now().add(Duration(hours: 3)),
);
```

### 3. **Automatic Reschedule on App Launch**
When the app starts and todos are loaded, all active reminders (with future reminder times) are automatically rescheduled. This ensures reminders persist even if the app is force-closed or crashes.

**How it works:**
- `loadTodos()` automatically calls `_rescheduleReminders()`
- Only reminders with times in the future are scheduled
- Past reminders are skipped silently

### 4. **Auto-Sync When Online**
Reminders are synced with Firebase along with todo data. When syncing from offline state, local reminder times are preserved and rescheduled.

**Setup auto-sync in your UI layer (e.g., after login):**

```dart
// In your auth page or app main after successful login:
@override
void initState() {
  super.initState();
  final uid = /* get from auth context */;
  todoViewModel.startAutoSync(uid); // Start listening for connectivity changes
}

@override
void dispose() {
  todoViewModel.stopAutoSync(); // Clean up listener
  super.dispose();
}
```

### 5. **Cancel Reminders**
When a todo is deleted, its notification is automatically cancelled.

```dart
// Deletion automatically cancels the reminder
await todoViewModel.deleteTodo(todoId, uid);
```

## Technical Implementation

### Files Modified/Created:

#### 1. **lib/core/notification_service.dart** (Enhanced)
- `scheduleNotification()` — Schedule a notification with timezone support
- `cancelNotification(int id)` — Cancel a specific notification
- `cancelAllNotifications()` — Cancel all scheduled notifications
- `getPendingNotifications()` — Query pending notifications
- Added error handling and logging

#### 2. **lib/data/local/sqlite_service.dart** (Schema Upgrade)
- Database version upgraded from 2 → 3
- Added `reminderTime`, `dueDate`, `priority` columns to `todos` table
- Includes `onUpgrade` callback for safe migration from older schemas
- Handles both new installs (onCreate) and upgrades gracefully

#### 3. **lib/data/models/todo_model.dart** (Improved)
- Fixed `fromMap()` to safely handle nullable timestamp fields
- Proper type casting to prevent runtime errors when loading from DB

#### 4. **lib/viewmodels/todo_viewmodel.dart** (Enhanced)
- `_rescheduleReminders()` — Reschedule all active reminders after loading todos
- `editTodo()` enhanced with `newReminderTime` parameter; cancels old reminder and schedules new one
- `deleteTodo()` now cancels associated notification
- `startAutoSync(uid)` / `stopAutoSync()` — Listen to connectivity changes and auto-sync when online
- Proper disposal of connectivity listener in `dispose()`

## Database Schema (v3)

```sql
CREATE TABLE todos(
  id TEXT PRIMARY KEY,
  title TEXT,
  isDone INTEGER,
  isSynced INTEGER,
  updatedAt INTEGER,
  reminderTime INTEGER,        -- Milliseconds since epoch
  dueDate INTEGER,              -- Milliseconds since epoch
  priority INTEGER              -- 1=Low, 2=Medium, 3=High
)
```

## Conflict Resolution for Reminders

When syncing with Firebase after offline changes:
- Timestamps (`updatedAt`) determine which version wins (local vs. remote)
- Latest `updatedAt` = authoritative todo (including reminderTime)
- Reminders are automatically rescheduled after merge

## Usage in UI

### Example: Add Todo with Reminder
```dart
showDateTimePicker(
  onConfirm: (reminderTime) {
    todoViewModel.addTodo(
      titleController.text,
      uid,
      reminderTime: reminderTime,
      priority: selectedPriority,
      dueDate: selectedDueDate,
    );
  },
);
```

### Example: Edit Todo with New Reminder
```dart
showReminderEditor(
  currentTodo: todo,
  onSave: (newReminderTime) {
    todoViewModel.editTodo(
      todo,
      uid,
      newReminderTime: newReminderTime,
    );
  },
);
```

### Example: Delete with Cleanup
```dart
todoViewModel.deleteTodo(todo.id, uid);
// Notification is automatically cancelled
```

## Important Notes

1. **Timezone Support**
   - Uses `timezone` package with local device timezone
   - Reminders are stored as milliseconds since epoch (timezone-agnostic)

2. **Permissions (Android)**
   - Ensure `SCHEDULE_EXACT_ALARM` and `POST_NOTIFICATIONS` permissions are in `AndroidManifest.xml`
   - The app already has `flutter_local_notifications` configured

3. **Web Limitations**
   - SQLite is not supported on web, so local persistence is disabled
   - Firebase reminders still sync and work on Firebase, but won't reschedule on web reload

4. **Error Handling**
   - All notification operations are wrapped in try-catch blocks
   - Failures in scheduling/canceling don't crash the app
   - Errors are logged for debugging

5. **Performance**
   - Rescheduling happens asynchronously after `loadTodos()`
   - Doesn't block UI during large todo loads

## Testing Commands

```bash
# Format all modified files
dart format lib/

# Run analysis
flutter analyze

# Run the app
flutter run

# Build for Android (if needed)
flutter build apk

# Build for iOS (if needed)
flutter build ios
```

## Future Enhancements

- [ ] Snooze reminders from notification action
- [ ] Recurring reminders (daily, weekly, monthly)
- [ ] Custom notification sounds
- [ ] Reminder batching for performance
- [ ] Backup/restore reminder schedules to Firebase
- [ ] Silent hours / do-not-disturb periods

## FAQ

**Q: What happens if my app crashes before a reminder fires?**
A: When you reopen the app, `loadTodos()` reschedules all active reminders. So reminders always work even after crashes.

**Q: Can I have multiple reminders per todo?**
A: Currently, one reminder per todo. To support multiple, you'd need to:
1. Create a separate `reminders` table in SQLite
2. Update `TodoModel` to contain a list of reminder times
3. Modify notification IDs to be composite (todo_id + reminder_index)

**Q: Do reminders work offline?**
A: Reminders are scheduled locally by the OS, so they work offline. When you sync online later, the reminder times are synced to Firebase as part of the todo.

**Q: How do I test reminders in development?**
A: Use `flutter_local_notifications` test utilities or set a test reminder for 5 seconds from now and observe.

**Q: Why is a deprecated warning shown for `androidAllowWhileIdle`?**
A: This is a known deprecation in newer versions of `flutter_local_notifications`. It can be migrated to `androidScheduleMode` in a future update.
