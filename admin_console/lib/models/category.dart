class Category {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final String path;
  final int depth;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.parentId,
    required this.path,
    required this.depth,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      parentId: json['parentId'],
      path: json['path'],
      depth: json['depth'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'parentId': parentId,
    'path': path,
    'depth': depth,
  };

  bool get isRoot => parentId == null;

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? parentId,
    String? path,
    int? depth,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
      path: path ?? this.path,
      depth: depth ?? this.depth,
      children: children ?? this.children,
    );
  }
}