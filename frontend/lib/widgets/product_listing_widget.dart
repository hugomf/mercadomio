import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/error_handler.dart';
import 'error_state_widget.dart';

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

  // Helper method to get absolute image URL based on platform
  String getAbsoluteImageUrl(String baseApiUrl) {
    if (imageUrl.isEmpty) return 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=Natura';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl; // Already absolute
    }

    // Use dedicated image server on port 8081 with original filenames
    final imageServer = baseApiUrl.replaceAll(':8080', ':8081');
    return '$imageServer$imageUrl';
  }

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
  AppError? _error;
  bool _isRetrying = false;

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
      _error = null;
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
    if (!loadMore) {
      setState(() {
        _error = null;
        isLoading = true;
      });
    }

    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.64.73:8080';

      // Build URL based on search mode
      final String url;
      if (isSearchMode && currentSearchQuery.isNotEmpty) {
        url = '$apiUrl/api/products?q=${Uri.encodeComponent(currentSearchQuery)}&page=$currentPage&limit=$itemsPerPage';
      } else {
        url = '$apiUrl/api/products?page=$currentPage&limit=$itemsPerPage';
      }

      final response = await ErrorHandler.executeWithRetry(
        () async {
          return await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );
        },
        config: const RetryConfig(maxRetries: 2, initialDelay: Duration(seconds: 1)),
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> productsData = responseData['data'] ?? [];
          final int totalItems = responseData['total'] ?? productsData.length;
          print('📄 Backend response: total=${responseData['total']}, data length=${productsData.length}, calculated totalItems=$totalItems');

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

          if (mounted) {
            setState(() {
              if (loadMore) {
                products.addAll(parsedProducts);
                print('📄 Added ${parsedProducts.length} products, total now: ${products.length}');
              } else {
                products = parsedProducts;
                print('📄 Loaded ${parsedProducts.length} products for page $currentPage');
              }
              hasMore = products.length < totalItems;
              print('📄 Pagination status: ${products.length}/$totalItems products, hasMore=$hasMore');
              isLoading = false;
              _error = null;
              _isRetrying = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = AppError(
                type: ErrorType.parsing,
                message: 'Failed to parse product data',
                originalError: e,
              );
              isLoading = false;
              _isRetrying = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = AppError(
              type: ErrorType.server,
              message: 'Server returned status ${response.statusCode}',
            );
            isLoading = false;
            _isRetrying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.createError(e);
          isLoading = false;
          _isRetrying = false;
        });
      }
    }
  }

  void _loadMoreProducts() {
    print('📄 _loadMoreProducts called: hasMore=$hasMore, isLoading=$isLoading, currentPage=$currentPage');
    if (hasMore && !isLoading) {
      final nextPage = currentPage + 1;
      print('📄 Loading page $nextPage, current products: ${products.length}');
      setState(() {
        currentPage = nextPage;
        isLoading = true;
      });
      _fetchProducts(loadMore: true);
    } else {
      print('📄 Load more skipped: hasMore=$hasMore, isLoading=$isLoading');
    }
  }

  // Helper method to get API URL
  Future<String> _getApiUrl() async {
    await dotenv.load();
    return dotenv.env['API_URL'] ?? 'http://192.168.64.73:8080';
  }

  void refreshProducts() {
    setState(() {
      currentPage = 1;
      isLoading = true;
      products = [];
      isSearchMode = false;
      currentSearchQuery = '';
      _error = null;
      _isRetrying = false;
    });
    _fetchProducts();
  }

  Future<void> _retryFetch() async {
    setState(() {
      _isRetrying = true;
      isLoading = true;
    });
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && products.isEmpty) {
      return ErrorStateWidget(
        error: _error!,
        onRetry: _retryFetch,
        isRetrying: _isRetrying,
      );
    }

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
              // More flexible scroll detection - trigger when near bottom
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                  hasMore && !isLoading) {
                print('🔄 Triggering load more: pixels=${scrollInfo.metrics.pixels}, max=${scrollInfo.metrics.maxScrollExtent}');
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
              ? FutureBuilder<String>(
                  future: _getApiUrl(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final absoluteImageUrl = product.getAbsoluteImageUrl(snapshot.data!);
                    return Image.network(
                      absoluteImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // print('🖼️ Image load error for ${product.name}: $error');
                    // print('🔗 Image URL: ${product.imageUrl}');
                    return const Icon(Icons.image_not_supported, size: 50, color: Colors.red);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      // print('✅ Image loaded successfully for ${product.name}');
                      return child;
                    }
                    // print('⏳ Loading image for ${product.name}...');
                    return const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
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
                  final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.64.73:8080';
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
