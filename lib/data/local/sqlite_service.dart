import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_model.dart';

class SQLiteService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'todo.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE todos(
          id TEXT PRIMARY KEY,
          title TEXT,
          isDone INTEGER,
          isSynced INTEGER,
          updatedAt INTEGER
        )
        ''');
      },
    );
  }

  Future<void> insertTodo(TodoModel todo) async {
    final db = await database;
    await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TodoModel>> getTodos() async {
    final db = await database;
    final data = await db.query('todos');
    return data.map((e) => TodoModel.fromMap(e)).toList();
  }

    Future<void> updateTodo(TodoModel todo) async {
    final db = await database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}
