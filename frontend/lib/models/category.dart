class Category {
  final String id;
  String name;
  String? description;
  String? parentId;
  List<Category> children;

  bool get hasChildren => children.isNotEmpty;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentId: json['parentId'],
      children: json['children'] != null
        ? List<dynamic>.from(json['children'])
            .whereType<Map<String, dynamic>>()
            .map((child) => Category.fromJson(child))
            .toList()
        : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}