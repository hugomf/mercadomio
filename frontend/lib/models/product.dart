class Product {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl; // Main image for backward compatibility
  final List<ProductImage> images;
  final List<String>? categories;
  final String sku;
  final String barcode;
  final String? category;
  final List<Variant> variants;
  final List<Review> reviews;
  final double averageRating;
  final int reviewCount;
  final List<String> relatedProducts;
  final List<String> tags;
  final bool isActive;
  final Map<String, dynamic>? customAttributes;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    this.images = const [],
    this.categories,
    this.category,
    required this.sku,
    required this.barcode,
    this.variants = const [],
    this.reviews = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.relatedProducts = const [],
    this.tags = const [],
    this.isActive = true,
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
          : (json['images'] != null && (json['images'] as List).isNotEmpty)
            ? (json['images'] as List).firstWhere(
                (img) => img['isMain'] == true,
                orElse: () => json['images'][0],
              )['url']?.toString() ?? 'https://via.placeholder.com/150'
            : 'https://via.placeholder.com/150',
        images: json['images'] != null
          ? (json['images'] as List).map((img) => ProductImage.fromJson(img)).toList()
          : [],
        categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
        category: json['category']?.toString(),
        sku: json['sku']?.toString() ?? '',
        barcode: json['barcode']?.toString() ?? '',
        variants: json['variants'] != null
          ? (json['variants'] as List).map((v) => Variant.fromJson(v)).toList()
          : [],
        reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((r) => Review.fromJson(r)).toList()
          : [],
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['reviewCount'] as int?) ?? 0,
        relatedProducts: json['relatedProducts'] != null
          ? List<String>.from(json['relatedProducts'])
          : [],
        tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
        isActive: (json['isActive'] as bool?) ?? true,
        customAttributes: json['customAttributes'] != null
          ? Map<String, dynamic>.from(json['customAttributes'])
          : null,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ProductImage {
  final String id;
  final String url;
  final String altText;
  final int order;
  final bool isMain;

  ProductImage({
    required this.id,
    required this.url,
    required this.altText,
    this.order = 0,
    this.isMain = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      altText: json['altText']?.toString() ?? '',
      order: (json['order'] as int?) ?? 0,
      isMain: (json['isMain'] as bool?) ?? false,
    );
  }
}

class Variant {
  final String variantId;
  final String name;
  final double price;
  final int stock;
  final String sku;
  final String imageUrl;
  final bool isAvailable;

  Variant({
    required this.variantId,
    required this.name,
    required this.price,
    required this.stock,
    required this.sku,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      variantId: json['variantId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as int?) ?? 0,
      sku: json['sku']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isAvailable: (json['isAvailable'] as bool?) ?? true,
    );
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      rating: (json['rating'] as int?) ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    );
  }
}
