class TodoModel {
  String id;
  String title;
  bool isDone;
  bool isSynced;
  int updatedAt;
  DateTime? reminderTime;

TodoModel({
  required this.id,
  required this.title,
  required this.isDone,
  required this.isSynced,
  required this.updatedAt,
  this.reminderTime,
});


  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isDone': isDone ? 1 : 0,
        'isSynced': isSynced ? 1 : 0,
        'updatedAt': updatedAt,
        'reminderTime': reminderTime?.millisecondsSinceEpoch,
      };

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
      isSynced: map['isSynced'] == 1,
      updatedAt: map['updatedAt'],
      reminderTime: map['reminderTime'] != null
    ? DateTime.fromMillisecondsSinceEpoch(map['reminderTime'])
    : null,
    );
  }
}
