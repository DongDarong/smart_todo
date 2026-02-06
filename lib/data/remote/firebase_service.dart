import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTodo(String uid, TodoModel todo) async {
    try {
      print('🔥 Writing todo to Firestore...');
      print('UID: $uid');
      print('TODO ID: ${todo.id}');
      print('DATA: ${todo.toMap()}');

      await _db
          .collection('users')
          .doc(uid)
          .collection('todos')
          .doc(todo.id)
          .set(todo.toMap());

      print('✅ Firestore write SUCCESS');
    } catch (e) {
      print('❌ Firestore write FAILED: $e');
    }
  }

  Future<List<TodoModel>> fetchTodos(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('todos')
        .get();

    return snapshot.docs.map((doc) => TodoModel.fromMap(doc.data())).toList();
  }

  Future<void> updateTodo(String uid, TodoModel todo) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(todo.id)
        .update(todo.toMap());
  }

  Future<void> deleteTodo(String uid, String id) async {
    await _db.collection('users').doc(uid).collection('todos').doc(id).delete();
  }
}
