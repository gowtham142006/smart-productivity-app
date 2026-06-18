class CategoryModel {
  final String id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.icon = 'folder',
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#6C63FF',
      icon: json['icon'] ?? 'folder',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}
