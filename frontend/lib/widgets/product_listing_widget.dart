import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String description;
  final String type;
  final String category;
  final double basePrice;
  final String sku;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.basePrice,
    required this.sku,
    required this.imageUrl,
  });

  // Convenience getter for price (using basePrice)
  double get price => basePrice;

  factory Product.fromJson(Map<String, dynamic> json) {

    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) return double.tryParse(price) ?? 0.0;
      return 0.0;
    }

    String parseString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    return Product(
      id: parseString(json['id'], 'unknown'),
      name: parseString(json['name'], 'Unnamed Product'),
      description: parseString(json['description'], ''),
      type: parseString(json['type'], 'physical'),
      category: parseString(json['category'], 'general'),
      basePrice: parsePrice(json['basePrice']),
      sku: parseString(json['sku'], ''),
      imageUrl: parseString(json['imageUrl'], 'https://via.placeholder.com/150'),
    );
  }
}

class ProductListingWidget extends StatefulWidget {
  final List<Product>? initialProducts;

  const ProductListingWidget({
    super.key,
    this.initialProducts,
  });

  @override
  ProductListingWidgetState createState() => ProductListingWidgetState();
}

class ProductListingWidgetState extends State<ProductListingWidget> {
  List<Product> products = [];
  bool isLoading = true;
  int currentPage = 1;
  bool hasMore = true;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts == null) {
      _fetchProducts();
    } else {
      setState(() {
        products = widget.initialProducts!;
        isLoading = false;
      });
    }
  }

  void updateProducts(List<Product> filteredProducts) {
    if (mounted) {
      setState(() {
        products = filteredProducts;
      });
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      final url = '$apiUrl/api/products?page=$currentPage&limit=$itemsPerPage';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productsData = responseData['data'] ?? [];
        final int totalItems = responseData['meta']?['totalItems'] ?? productsData.length;

        setState(() {
          if (loadMore) {
            products.addAll(productsData.map((json) => Product.fromJson(json)));
          } else {
            products = productsData.map((json) => Product.fromJson(json)).toList();
          }
          hasMore = products.length < totalItems;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _loadMoreProducts() {
    if (hasMore && !isLoading) {
      setState(() {
        currentPage++;
        isLoading = true;
      });
      _fetchProducts(loadMore: true);
    }
  }

  void refreshProducts() {
    setState(() {
      currentPage = 1;
      isLoading = true;
      products = [];
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && hasMore) {
          _loadMoreProducts();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: products.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
        final product = products[index];
        return Card(
          child: ListTile(
            leading: product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 50);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                )
              : const Icon(Icons.shopping_bag, size: 50),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$${product.price.toStringAsFixed(2)}'),
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
                  final response = await http.post(
                    Uri.parse('$apiUrl/api/cart'),
                    body: json.encode({
                      'productId': product.id,
                      'quantity': 1,
                      'price': product.price
                    }),
                    headers: {'Content-Type': 'application/json'},
                  );

                  if (response.statusCode == 200) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Added ${product.name} to cart')),
                      );
                    }
                  } else {
                    throw Exception('Failed to add to cart');
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to add to cart: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      ),
    );
  }
}
