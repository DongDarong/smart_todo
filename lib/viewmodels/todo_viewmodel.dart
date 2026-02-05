import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repository/todo_repository.dart';
import '../data/models/todo_model.dart';
import '../core/notification_service.dart';

class TodoViewModel extends ChangeNotifier {
  final TodoRepository repo = TodoRepository();
  List<TodoModel> todos = [];

  // ================= LOAD TODOS =================
  Future<void> loadTodos(String uid) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() !=
            ConnectivityResult.none;

    todos = await repo.loadTodos(uid, isOnline);
    notifyListeners();
  }

  // ================= ADD TODO =================
  Future<void> addTodo(
    String title,
    String uid, {
    DateTime? reminderTime,
  }) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() !=
            ConnectivityResult.none;

    final TodoModel todo = TodoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      isDone: false,
      isSynced: isOnline,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      reminderTime: reminderTime,
    );

    await repo.addTodo(todo, uid, isOnline);
    todos.add(todo);
    notifyListeners();

    // Schedule reminder if exists
    if (reminderTime != null) {
      await NotificationService.scheduleNotification(
        id: int.parse(todo.id),
        title: 'Todo Reminder',
        body: todo.title,
        scheduledTime: reminderTime,
      );
    }
  }

  // ================= TOGGLE DONE =================
  Future<void> toggleDone(
    TodoModel todo,
    String uid,
  ) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() !=
            ConnectivityResult.none;

    final TodoModel updatedTodo = TodoModel(
      id: todo.id,
      title: todo.title,
      isDone: !todo.isDone,
      isSynced: isOnline,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      reminderTime: todo.reminderTime,
    );

    await repo.updateTodo(updatedTodo, uid, isOnline);

    final int index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = updatedTodo;
      notifyListeners();
    }
  }

  // ================= DELETE TODO =================
  Future<void> deleteTodo(
    String id,
    String uid,
  ) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() !=
            ConnectivityResult.none;

    await repo.deleteTodo(id, uid, isOnline);
    todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ================= SYNC WHEN ONLINE =================
  Future<void> syncIfOnline(String uid) async {
    final bool isOnline =
        await Connectivity().checkConnectivity() !=
            ConnectivityResult.none;

    if (isOnline) {
      await repo.syncTodos(uid);
      await loadTodos(uid);
    }
  }

  // ================= STATISTICS =================
  int get totalTodos => todos.length;

  int get completedTodos =>
      todos.where((t) => t.isDone).length;

  int get pendingTodos =>
      todos.where((t) => !t.isDone).length;

  double get completionRate {
    if (todos.isEmpty) return 0;
    return (completedTodos / totalTodos) * 100;
  }
}
