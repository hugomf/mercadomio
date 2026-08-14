// Product model matching backend services.Product JSON shape.
class ProductVariant {
  final String variantId;
  final Map<String, dynamic> attributes;
  final double priceAdjustment;
  final String sku;
  final String barcode;
  int stock;

  ProductVariant({
    required this.variantId,
    required this.attributes,
    required this.priceAdjustment,
    required this.sku,
    required this.barcode,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        variantId: json['variantId'] as String? ?? '',
        attributes: (json['attributes'] as Map?)?.cast<String, dynamic>() ??
            const {},
        priceAdjustment:
            (json['priceAdjustment'] as num?)?.toDouble() ?? 0,
        sku: json['sku'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        stock: (json['stock'] as num?)?.toInt() ?? 0,
      );
}

class Product {
  final String id;
  final String name;
  final double basePrice;
  final String sku;
  final String imageUrl;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.sku,
    required this.imageUrl,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
        sku: json['sku'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        variants: ((json['variants'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ProductVariant.fromJson)
            .toList(),
      );
}

class ProductsPage {
  final List<Product> products;
  final int total;
  final int page;
  final int limit;

  ProductsPage({
    required this.products,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ProductsPage.fromJson(Map<String, dynamic> json) => ProductsPage(
        products: ((json['data'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Product.fromJson)
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
      );
}