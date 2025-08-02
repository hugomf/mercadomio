class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final List<String> categoryIds;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.categoryIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      categoryIds: List<String>.from(json['categoryIds']),
    );
  }
}