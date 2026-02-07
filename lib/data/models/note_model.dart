class NoteModel {
  final String id;
  final String title;
  final String content;
  final int updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    int? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    final content = map['content'] as String? ?? '';
    final title =
        map['title'] as String? ??
        (content.isNotEmpty ? content.split('\n').first : '');

    return NoteModel(
      id: map['id'] as String,
      title: title,
      content: content,
      updatedAt: (map['updatedAt'] ?? 0) as int,
    );
  }
}
