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
  final String barcode;
  final String imageUrl;
  final List<dynamic> variants;
  final Map<String, dynamic> customAttributes;
  final Map<String, String> identifiers;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.basePrice,
    required this.sku,
    required this.barcode,
    required this.imageUrl,
    required this.variants,
    required this.customAttributes,
    required this.identifiers,
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

    Map<String, String> parseStringMap(dynamic value) {
      if (value == null) return {};
      if (value is! Map) return {};

      final Map<String, String> result = {};
      value.forEach((key, val) {
        if (key != null && val != null) {
          result[key.toString()] = val.toString();
        }
      });
      return result;
    }

    return Product(
      id: parseString(json['id'], 'unknown'),
      name: parseString(json['name'], 'Unnamed Product'),
      description: parseString(json['description'], ''),
      type: parseString(json['type'], 'physical'),
      category: parseString(json['category'], 'general'),
      basePrice: parsePrice(json['basePrice']),
      sku: parseString(json['sku'], ''),
      barcode: parseString(json['barcode'], ''),
      imageUrl: parseString(json['imageUrl'], 'https://via.placeholder.com/150'),
      variants: List<dynamic>.from(json['variants'] ?? []),
      customAttributes: Map<String, dynamic>.from(json['customAttributes'] ?? {}),
      identifiers: parseStringMap(json['identifiers']),
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

  // Search state
  bool isSearchMode = false;
  String currentSearchQuery = '';
  int searchTotalItems = 0;

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

  void searchProducts(String query) {
    if (query.isEmpty) {
      // Clear search and return to normal mode
      refreshProducts();
      return;
    }

    setState(() {
      currentSearchQuery = query;
      isSearchMode = true;
      currentPage = 1;
      isLoading = true;
      products = [];
      hasMore = true;
    });
    _fetchProducts();
  }

  // Keep this method for backward compatibility but mark as deprecated
  @Deprecated('Use searchProducts() instead for better pagination support')
  void updateProducts(List<Product> filteredProducts) {
    if (mounted) {
      setState(() {
        products = filteredProducts;
        isSearchMode = false;
        hasMore = false; // Disable pagination for direct updates
      });
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

      // Build URL based on search mode
      final String url;
      if (isSearchMode && currentSearchQuery.isNotEmpty) {
        url = '$apiUrl/api/products?q=${Uri.encodeComponent(currentSearchQuery)}&page=$currentPage&limit=$itemsPerPage';
      } else {
        url = '$apiUrl/api/products?page=$currentPage&limit=$itemsPerPage';
      }

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> productsData = responseData['data'] ?? [];
          final int totalItems = responseData['meta']?['totalItems'] ?? productsData.length;

          // Parse products with individual error handling
          final List<Product> parsedProducts = [];
          for (final productJson in productsData) {
            try {
              parsedProducts.add(Product.fromJson(productJson));
            } catch (e) {
              // Skip individual product parsing errors but continue with others
              continue;
            }
          }

          setState(() {
            if (loadMore) {
              products.addAll(parsedProducts);
            } else {
              products = parsedProducts;
            }
            hasMore = products.length < totalItems;
            isLoading = false;
          });
        } catch (e) {
          // JSON parsing error
          setState(() {
            isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to parse response: $e')),
            );
          }
        }
      } else {
        // Handle non-200 status codes
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')),
          );
        }
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
      final nextPage = currentPage + 1;
      setState(() {
        currentPage = nextPage;
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
      isSearchMode = false;
      currentSearchQuery = '';
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchMode ? Icons.search_off : Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey
            ),
            const SizedBox(height: 16),
            Text(
              isSearchMode
                ? 'No products found for "$currentSearchQuery"'
                : 'No products available',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchMode
                ? 'Try a different search term or browse all products'
                : 'Check back later for new products',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (isSearchMode) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => refreshProducts(),
                child: const Text('Browse All Products'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search indicator
        if (isSearchMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Searching for "$currentSearchQuery"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => refreshProducts(),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        // Product list
        Expanded(
          child: NotificationListener<ScrollNotification>(
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
          ),
        ),
      ],
    );
  }
}
