class NoteModel {
  final String id;

  final String title;

  final String content;

  final DateTime createdAt;

  NoteModel({
    required this.id,

    required this.title,

    required this.content,

    required this.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],

      title: json['title'],

      content: json['content'],

      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
