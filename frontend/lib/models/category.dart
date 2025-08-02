class Category {
  final String id;
  String name;
  String? description;
  String? parentId;
  List<String>? childrenIds;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.childrenIds,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentId: json['parentId'],
      childrenIds: json['childrenIds'] != null 
        ? List<String>.from(json['childrenIds'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'childrenIds': childrenIds,
    };
  }
}