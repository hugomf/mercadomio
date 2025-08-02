import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:async';
import '../services/error_handler.dart';
import '../services/cart_controller.dart';
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

  // Helper method to get absolute image URL with Cloudinary and Directus support
  String getAbsoluteImageUrl(String baseApiUrl) {
    if (imageUrl.isEmpty || imageUrl == 'null') return 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=Natura';

    // If it's already a full URL (Cloudinary, Directus, or other CDN), use it directly
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl; // Already absolute (Cloudinary, Directus, or other CDN)
    }

    // For relative URLs, try different fallback strategies
    if (imageUrl.startsWith('/')) {
      // Try dedicated image server first (port 8081)
      final imageServer = baseApiUrl.replaceAll(':8080', ':8081');
      return '$imageServer$imageUrl';
    }

    // Fallback to placeholder with product name
    final productName = Uri.encodeComponent(name.length > 8 ? name.substring(0, 8) : name);
    return 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=$productName';
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
      variants: json['variants'] != null ? List<dynamic>.from(json['variants']) : [],
      customAttributes: json['customAttributes'] != null ? Map<String, dynamic>.from(json['customAttributes']) : {},
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
  String? _apiUrl;

  final int itemsPerPage = 10;

  // Search state
  bool isSearchMode = false;
  String currentSearchQuery = '';
  int searchTotalItems = 0;

  @override
  void initState() {
    super.initState();
    _initializeApiUrl();
    if (widget.initialProducts == null) {
      _fetchProducts();
    } else {
      setState(() {
        products = widget.initialProducts!;
        isLoading = false;
      });
    }
  }

  // Pre-fetch API URL to avoid async issues
  Future<void> _initializeApiUrl() async {
    try {
      _apiUrl = await _getApiUrl();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppError(
            type: ErrorType.config,
            message: 'Failed to load API URL',
            originalError: e,
          );
        });
      }
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
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

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (!mounted) return;

    if (!loadMore) {
      setState(() {
        _error = null;
        isLoading = true;
        if (currentPage == 1) {
          products = [];
        }
      });
    }

    try {
      try {
        await dotenv.load().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Environment config loading timeout'),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = AppError(
            type: ErrorType.config,
            message: 'Failed to load environment configuration',
            originalError: e,
          );
          isLoading = false;
          _isRetrying = false;
        });
        return;
      }
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

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

          final List<Product> parsedProducts = [];
          for (final productJson in productsData) {
            try {
              parsedProducts.add(Product.fromJson(productJson));
            } catch (e) {
              continue;
            }
          }

          if (mounted) {
            setState(() {
              if (loadMore) {
                products.addAll(parsedProducts);
              } else {
                products = parsedProducts;
              }
              hasMore = products.length < totalItems;
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
    if (hasMore && !isLoading) {
      final nextPage = currentPage + 1;
      setState(() {
        currentPage = nextPage;
        isLoading = true;
      });
      _fetchProducts(loadMore: true);
    }
  }

  Future<String> _getApiUrl() async {
    await dotenv.load();
    return dotenv.env['API_URL'] ?? 'http://localhost:8080';
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && (products.isEmpty || _isRetrying)) {
      return ErrorStateWidget(
        error: _error!,
        onRetry: _retryFetch,
        isRetrying: _isRetrying,
      );
    }

    if (isLoading && products.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSearchMode ? Icons.search_off : Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isSearchMode
                    ? 'No matches for "$currentSearchQuery"'
                    : 'No products available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearchMode
                    ? 'Try a different search term'
                    : 'New products coming soon',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
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
        ),
      );
    }

    return Column(
      children: [
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
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200 &&
                  hasMore &&
                  !isLoading) {
                _loadMoreProducts();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: products.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final product = products[index];
                return Card(
                  key: ValueKey(product.id),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: _apiUrl == null
                        ? const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : product.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.getAbsoluteImageUrl(_apiUrl!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child:
                                      Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.red,
                                ),
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
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        // Capture ScaffoldMessenger before async operation
                        final messenger = ScaffoldMessenger.of(context);
                        final productName = product.name; // Capture product name
                        final productId = product.id; // Capture product ID
                        // Perform async operation
                        Future<void> addToCart() async {
                          final CartController cartController =
                              Get.find<CartController>();
                          try {
                            await cartController.addToCart(
                              productId: productId,
                              quantity: 1,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text('Added $productName to cart')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text('Failed to add to cart: $e')),
                            );
                          }
                        }

                        addToCart();
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