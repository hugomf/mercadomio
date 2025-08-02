class Product {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final List<String>? categories;
  final String sku;
  final String barcode;
  final Map<String, dynamic>? customAttributes;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    this.categories,
    required this.sku,
    required this.barcode,
    this.customAttributes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Product',
        description: json['description']?.toString() ?? '',
        basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
        imageUrl: (json['imageUrl']?.toString().isNotEmpty ?? false)
          ? json['imageUrl'].toString()
          : 'https://via.placeholder.com/150',
        categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
        sku: json['sku']?.toString() ?? '',
        barcode: json['barcode']?.toString() ?? '',
        customAttributes: json['customAttributes'] != null
          ? Map<String, dynamic>.from(json['customAttributes'])
          : null,
      );
    } catch (e) {
      print('Error parsing product: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}