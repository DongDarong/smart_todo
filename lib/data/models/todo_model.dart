class TodoModel {
  final String id;
  final String title;
  final String? description;
  final bool isDone;
  final bool isSynced;
  final int updatedAt;
  final DateTime? reminderTime;
  final DateTime? dueDate;
  final int priority;

  TodoModel({
    required this.id,
    required this.title,
    this.description,
    required this.isDone,
    required this.isSynced,
    required this.updatedAt,
    this.reminderTime,
    this.dueDate,
    this.priority = 2,
  });

  // ================= COPY WITH =================
  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    bool? isSynced,
    int? updatedAt,
    DateTime? reminderTime,
    DateTime? dueDate,
    int? priority,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderTime: reminderTime ?? this.reminderTime,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
    );
  }

  // ================= TO MAP (SQLite / Firebase) =================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'updatedAt': updatedAt,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priority,
    };
  }

  // ================= FROM MAP =================
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isDone: map['isDone'] == 1 || map['isDone'] == true,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      updatedAt: (map['updatedAt'] ?? 0) as int,
      reminderTime: map['reminderTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminderTime'] as int)
          : null,
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      priority: (map['priority'] ?? 2) as int,
    );
  }
}
