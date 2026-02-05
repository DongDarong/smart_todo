import '../local/sqlite_service.dart';
import '../remote/firebase_service.dart';
import '../models/todo_model.dart';

class TodoRepository {
  final SQLiteService local = SQLiteService();
  final FirebaseService remote = FirebaseService();

  Future<void> addTodo(
      TodoModel todo, String uid, bool isOnline) async {
    // Always save locally first (Offline-first)
    await local.insertTodo(todo);

    // Sync to cloud only if online
    if (isOnline) {
      await remote.addTodo(uid, todo);
    }
  }

  Future<List<TodoModel>> loadTodos(
      String uid, bool isOnline) async {
    if (isOnline) {
      // Fetch from Firebase
      final onlineTodos = await remote.fetchTodos(uid);

      // Cache to SQLite
      for (var todo in onlineTodos) {
        await local.insertTodo(todo);
      }
      return onlineTodos;
    }

    // Offline → load from SQLite
    return await local.getTodos();
  }

    Future<void> updateTodo(
      TodoModel todo, String uid, bool isOnline) async {
    await local.updateTodo(todo);

    if (isOnline) {
      await remote.updateTodo(uid, todo);
    }
  }

  Future<void> deleteTodo(
      String id, String uid, bool isOnline) async {
    await local.deleteTodo(id);

    if (isOnline) {
      await remote.deleteTodo(uid, id);
    }
  }

Future<void> syncTodos(String uid) async {
  final localTodos = await local.getTodos();

  for (var localTodo in localTodos) {
    if (!localTodo.isSynced) {
      final remoteTodos = await remote.fetchTodos(uid);

      final remoteTodo = remoteTodos
          .where((t) => t.id == localTodo.id)
          .toList();

      if (remoteTodo.isEmpty) {
        // No conflict → upload local
        await remote.addTodo(uid, localTodo);
      } else {
        // Conflict detected
        if (localTodo.updatedAt >
            remoteTodo.first.updatedAt) {
          // Local is newer → overwrite remote
          await remote.updateTodo(uid, localTodo);
        }
      }

      // Mark as synced
      final syncedTodo = TodoModel(
        id: localTodo.id,
        title: localTodo.title,
        isDone: localTodo.isDone,
        isSynced: true,
        updatedAt: localTodo.updatedAt,
      );

      await local.updateTodo(syncedTodo);
    }
  }
}

}
