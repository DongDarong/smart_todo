import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/models/todo_model.dart';
import '../data/repository/todo_repository.dart';
import '../core/notification_service.dart';

/// Status filter used by the UI and viewmodel
enum TodoStatusFilter { all, completed, pending }

class TodoViewModel extends ChangeNotifier {
  final TodoRepository repo = TodoRepository();

  StreamSubscription<ConnectivityResult>? _connectivitySub;

  List<TodoModel> todos = [];

  // -------------------- Smart Search & Filters --------------------
  String searchQuery = '';
  TodoStatusFilter statusFilter = TodoStatusFilter.all;
  final Set<int> priorityFilters = <int>{}; // empty = all
  DateTime? dateFrom;
  DateTime? dateTo;

  void setSearchQuery(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setStatusFilter(TodoStatusFilter f) {
    statusFilter = f;
    notifyListeners();
  }

  void togglePriorityFilter(int p) {
    if (priorityFilters.contains(p)) {
      priorityFilters.remove(p);
    } else {
      priorityFilters.add(p);
    }
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    dateFrom = from;
    dateTo = to;
    notifyListeners();
  }

  void clearFilters() {
    searchQuery = '';
    statusFilter = TodoStatusFilter.all;
    priorityFilters.clear();
    dateFrom = null;
    dateTo = null;
    notifyListeners();
  }

  /// Replace the selected priority filters
  void setPriorityFilters(Set<int> priorities) {
    priorityFilters.clear();
    priorityFilters.addAll(priorities);
    notifyListeners();
  }

  /// Apply currently selected search & filters to a provided list
  List<TodoModel> applyFilters(List<TodoModel> list) {
    return list.where((t) {
      // Search
      if (searchQuery.isNotEmpty &&
          !t.title.toLowerCase().contains(searchQuery.toLowerCase()))
        return false;
      // Status
      if (statusFilter == TodoStatusFilter.completed && !t.isDone) return false;
      if (statusFilter == TodoStatusFilter.pending && t.isDone) return false;
      // Priority
      if (priorityFilters.isNotEmpty && !priorityFilters.contains(t.priority))
        return false;
      // Date range
      if ((dateFrom != null || dateTo != null)) {
        if (t.dueDate == null)
          return false; // exclude if filtering by date but todo has no due date
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (dateFrom != null &&
            due.isBefore(
              DateTime(dateFrom!.year, dateFrom!.month, dateFrom!.day),
            ))
          return false;
        if (dateTo != null &&
            due.isAfter(DateTime(dateTo!.year, dateTo!.month, dateTo!.day)))
          return false;
      }
      return true;
    }).toList();
  }

  // =========================================================
  // LOAD TODOS
  // =========================================================
  Future<void> loadTodos(String uid) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    todos = await repo.loadTodos(uid, isOnline);

    // Reschedule all reminders for todos with reminder times in the future
    await _rescheduleReminders();

    notifyListeners();
  }

  /// Reschedule reminders for all todos with future reminder times
  Future<void> _rescheduleReminders() async {
    final now = DateTime.now();
    for (final todo in todos) {
      if (todo.reminderTime != null && todo.reminderTime!.isAfter(now)) {
        try {
          await NotificationService.scheduleNotification(
            id: int.parse(todo.id),
            title: 'Todo Reminder',
            body: todo.title,
            scheduledTime: todo.reminderTime!,
          );
        } catch (_) {
          // Silently ignore scheduling errors
        }
      }
    }
  }

  // =========================================================
  // ADD TODO
  // =========================================================
  Future<void> addTodo(
    String title,
    String uid, {
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    int priority = 2, // 1=Low, 2=Medium, 3=High
  }) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    final TodoModel todo = TodoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      isDone: false,
      isSynced: isOnline,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      dueDate: dueDate,
      reminderTime: reminderTime,
      priority: priority,
    );

    await repo.addTodo(todo, uid, isOnline);
    todos.add(todo);
    notifyListeners();

    // 🔔 Schedule reminder (optional)
    if (reminderTime != null) {
      await NotificationService.scheduleNotification(
        id: int.parse(todo.id),
        title: 'Todo Reminder',
        body: todo.title,
        scheduledTime: reminderTime,
      );
    }
  }

  // =========================================================
  // EDIT TODO  ✅
  // =========================================================
  Future<void> editTodo(
    TodoModel todo,
    String uid, {
    String? newTitle,
    String? newDescription,
    DateTime? newDueDate,
    int? newPriority,
    DateTime? newReminderTime,
  }) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    // Determine final reminder time (use new value, or keep old, or null)
    DateTime? finalReminderTime;
    if (newReminderTime != null) {
      finalReminderTime = newReminderTime;
    } else if (todo.reminderTime != null) {
      finalReminderTime = todo.reminderTime;
    }

    final TodoModel updatedTodo = todo.copyWith(
      title: newTitle ?? todo.title,
      description: newDescription ?? todo.description,
      dueDate: newDueDate ?? todo.dueDate,
      priority: newPriority ?? todo.priority,
      reminderTime: finalReminderTime,
      isSynced: isOnline,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Cancel old reminder if it exists
    try {
      await NotificationService.cancelNotification(int.parse(todo.id));
    } catch (_) {
      // Ignore errors
    }

    // Schedule new reminder if needed
    if (finalReminderTime != null &&
        finalReminderTime.isAfter(DateTime.now())) {
      try {
        await NotificationService.scheduleNotification(
          id: int.parse(updatedTodo.id),
          title: 'Todo Reminder',
          body: updatedTodo.title,
          scheduledTime: finalReminderTime,
        );
      } catch (_) {
        // Ignore errors
      }
    }

    await repo.updateTodo(updatedTodo, uid, isOnline);

    final int index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = updatedTodo;
      notifyListeners();
    }
  }

  // =========================================================
  // TOGGLE DONE
  // =========================================================
  Future<void> toggleDone(TodoModel todo, String uid) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    final TodoModel updatedTodo = todo.copyWith(
      isDone: !todo.isDone,
      isSynced: isOnline,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.updateTodo(updatedTodo, uid, isOnline);

    final int index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = updatedTodo;
      notifyListeners();
    }
  }

  // =========================================================
  // DELETE TODO
  // =========================================================
  Future<void> deleteTodo(String id, String uid) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    // Cancel associated notification if any
    try {
      await NotificationService.cancelNotification(int.parse(id));
    } catch (_) {
      // Ignore errors
    }

    await repo.deleteTodo(id, uid, isOnline);
    todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // =========================================================
  // SYNC WHEN ONLINE
  // =========================================================
  Future<void> syncIfOnline(String uid) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    if (isOnline) {
      await repo.syncTodos(uid);
      await loadTodos(uid);
    }
  }

  /// Start automatic sync when connectivity is regained. Call with the current `uid`.
  void startAutoSync(String uid) {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncIfOnline(uid);
      }
    });
  }

  /// Stop automatic sync listener.
  void stopAutoSync() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // =========================================================
  // STATISTICS
  // =========================================================
  int get totalTodos => todos.length;

  int get completedCount => todos.where((t) => t.isDone).length;

  int get pendingCount => todos.where((t) => !t.isDone).length;

  double get completionRate {
    if (todos.isEmpty) return 0;
    return (completedCount / totalTodos) * 100;
  }

  // =========================================================
  // SMART CATEGORIZATION
  // =========================================================
  DateTime get _today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // 🟢 TODAY
  List<TodoModel> get todayTodos {
    return todos.where((t) {
      if (t.isDone || t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d == _today;
    }).toList();
  }

  // 🔵 UPCOMING
  List<TodoModel> get upcomingTodos {
    return todos.where((t) {
      if (t.isDone || t.dueDate == null) return false;
      return t.dueDate!.isAfter(_today);
    }).toList();
  }

  // 🔴 OVERDUE
  List<TodoModel> get overdueTodos {
    return todos.where((t) {
      if (t.isDone || t.dueDate == null) return false;
      return t.dueDate!.isBefore(_today);
    }).toList();
  }

  // ✅ COMPLETED
  List<TodoModel> get completedTodos {
    return todos.where((t) => t.isDone).toList();
  }

  // =========================================================
  // SORT BY PRIORITY (HIGH → LOW)
  // =========================================================
  List<TodoModel> sortByPriority(List<TodoModel> list) {
    final sorted = [...list];
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }
}
