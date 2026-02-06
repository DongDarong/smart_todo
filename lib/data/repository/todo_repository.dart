import 'package:flutter/foundation.dart';
import '../local/sqlite_service.dart';
import '../remote/firebase_service.dart';
import '../models/todo_model.dart';
import '../local/pending_operations.dart';

class TodoRepository {
  final SQLiteService local = SQLiteService();
  final FirebaseService remote = FirebaseService();
  final PendingOperationsService pending = PendingOperationsService();

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
      await pending.removePendingDelete(id);
    } else {
      // If offline, remember this id so it will be deleted remotely on next sync
      await pending.addPendingDelete(id);
    }
  }

  // ================= SYNC =================
  Future<void> syncTodos(String uid) async {
    // ❌ WEB does not sync local DB
    if (kIsWeb) return;
    // First, process any pending deletes
    final pendingDeletes = await pending.getPendingDeletes();
    for (final id in pendingDeletes) {
      try {
        await remote.deleteTodo(uid, id);
        await pending.removePendingDelete(id);
      } catch (_) {
        // Leave it for the next sync attempt
      }
    }

    final localTodos = await local.getTodos();
    final remoteTodos = await remote.fetchTodos(uid);

    final Map<String, TodoModel> localMap = {
      for (var t in localTodos) t.id: t,
    };
    final Map<String, TodoModel> remoteMap = {
      for (var t in remoteTodos) t.id: t,
    };

    final allIds = <String>{}..addAll(localMap.keys)..addAll(remoteMap.keys);

    for (final id in allIds) {
      final localTodo = localMap[id];
      final remoteTodo = remoteMap[id];

      if (localTodo != null && remoteTodo != null) {
        // Both exist: latest updatedAt wins
        if (localTodo.updatedAt > remoteTodo.updatedAt) {
          await remote.addTodo(uid, localTodo);
          await local.updateTodo(localTodo.copyWith(isSynced: true));
        } else if (remoteTodo.updatedAt > localTodo.updatedAt) {
          await local.updateTodo(remoteTodo.copyWith(isSynced: true));
        }
      } else if (localTodo != null && remoteTodo == null) {
        // Local only
        if (!localTodo.isSynced) {
          // Created/updated offline — push to remote
          await remote.addTodo(uid, localTodo);
          await local.updateTodo(localTodo.copyWith(isSynced: true));
        } else {
          // Previously synced but remote missing => remote deletion, delete local
          await local.deleteTodo(localTodo.id);
        }
      } else if (localTodo == null && remoteTodo != null) {
        // Remote only: insert into local
        await local.insertTodo(remoteTodo.copyWith(isSynced: true));
      }
    }
  }
}
