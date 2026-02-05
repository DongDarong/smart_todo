class TodoModel {
  final String id;
  final String title;
  final bool isDone;
  final bool isSynced;
  final int updatedAt;
  final DateTime? reminderTime;

  TodoModel({
    required this.id,
    required this.title,
    required this.isDone,
    required this.isSynced,
    required this.updatedAt,
    this.reminderTime,
  });

  // ================= COPY WITH =================
  TodoModel copyWith({
    String? id,
    String? title,
    bool? isDone,
    bool? isSynced,
    int? updatedAt,
    DateTime? reminderTime,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderTime: reminderTime ?? this.reminderTime,
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
    );
  }
}
