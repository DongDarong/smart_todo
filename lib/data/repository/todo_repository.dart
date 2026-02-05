import 'package:flutter/foundation.dart';
import '../local/sqlite_service.dart';
import '../remote/firebase_service.dart';
import '../models/todo_model.dart';

class TodoRepository {
  final SQLiteService local = SQLiteService();
  final FirebaseService remote = FirebaseService();

  // ================= ADD TODO =================
  Future<void> addTodo(
    TodoModel todo,
    String uid,
    bool isOnline,
  ) async {
    // ❌ WEB: Skip SQLite
    if (!kIsWeb) {
      await local.insertTodo(todo);
    }

    // ✅ Firebase always allowed
    if (isOnline) {
      await remote.addTodo(uid, todo);
    }
  }

  // ================= LOAD TODOS =================
  Future<List<TodoModel>> loadTodos(
    String uid,
    bool isOnline,
  ) async {
    // 🌐 WEB: Firebase only
    if (kIsWeb) {
      return await remote.fetchTodos(uid);
    }

    // 📱 MOBILE / DESKTOP
    if (isOnline) {
      final onlineTodos = await remote.fetchTodos(uid);
      for (var todo in onlineTodos) {
        await local.insertTodo(todo);
      }
      return onlineTodos;
    }

    return await local.getTodos();
  }

  // ================= UPDATE TODO =================
  Future<void> updateTodo(
    TodoModel todo,
    String uid,
    bool isOnline,
  ) async {
    if (!kIsWeb) {
      await local.updateTodo(todo);
    }

    if (isOnline) {
      await remote.updateTodo(uid, todo);
    }
  }

  // ================= DELETE TODO =================
  Future<void> deleteTodo(
    String id,
    String uid,
    bool isOnline,
  ) async {
    if (!kIsWeb) {
      await local.deleteTodo(id);
    }

    if (isOnline) {
      await remote.deleteTodo(uid, id);
    }
  }

  // ================= SYNC =================
  Future<void> syncTodos(String uid) async {
    // ❌ WEB does not sync local DB
    if (kIsWeb) return;

    final localTodos = await local.getTodos();
    final remoteTodos = await remote.fetchTodos(uid);

    for (var localTodo in localTodos) {
      final remoteTodo = remoteTodos
          .where((t) => t.id == localTodo.id)
          .toList();

      if (remoteTodo.isEmpty ||
          localTodo.updatedAt >
              remoteTodo.first.updatedAt) {
        await remote.addTodo(uid, localTodo);
        await local.updateTodo(
          localTodo.copyWith(isSynced: true),
        );
      }
    }
  }
}
