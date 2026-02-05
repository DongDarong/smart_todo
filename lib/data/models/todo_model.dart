class TodoModel {
  final String id;
  final String title;
  final bool isDone;
  final bool isSynced;
  final int updatedAt;
  final DateTime? reminderTime;
  final DateTime? dueDate;
  final int priority;

TodoModel({
  required this.id,
  required this.title,
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
      isDone: map['isDone'] == 1 || map['isDone'] == true,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      updatedAt: map['updatedAt'] as int,
      reminderTime: map['reminderTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['reminderTime'],
            )
          : null,
          dueDate: map['dueDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
            : null,
        priority: map['priority'] ?? 2,

    );
  }
}
