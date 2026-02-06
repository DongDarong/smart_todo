import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_model.dart';

class SQLiteService {
  static Database? _db;

  /// Get database instance (DISABLED ON WEB)
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web platform');
    }

    _db ??= await initDB();
    return _db!;
  }

  /// Initialize database
  Future<Database> initDB() async {
    final String path = join(await getDatabasesPath(), 'todo.db');

    return openDatabase(
      path,
      version: 4, // ⬅️ incremented for description field
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE todos(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            isDone INTEGER,
            isSynced INTEGER,
            updatedAt INTEGER,
            reminderTime INTEGER,
            dueDate INTEGER,
            priority INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Add missing columns for versions < 3
          await db.execute('ALTER TABLE todos ADD COLUMN reminderTime INTEGER');
          await db.execute('ALTER TABLE todos ADD COLUMN dueDate INTEGER');
          await db.execute(
            'ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 2',
          );
        }
        if (oldVersion < 4) {
          // Add description column for version 4
          await db.execute('ALTER TABLE todos ADD COLUMN description TEXT');
        }
      },
    );
  }

  /// Insert todo
  Future<void> insertTodo(TodoModel todo) async {
    if (kIsWeb) return;

    final db = await database;
    await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all todos
  Future<List<TodoModel>> getTodos() async {
    if (kIsWeb) return [];

    final db = await database;
    final data = await db.query('todos');
    return data.map((e) => TodoModel.fromMap(e)).toList();
  }

  /// Update todo
  Future<void> updateTodo(TodoModel todo) async {
    if (kIsWeb) return;

    final db = await database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// Delete todo
  Future<void> deleteTodo(String id) async {
    if (kIsWeb) return;

    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
