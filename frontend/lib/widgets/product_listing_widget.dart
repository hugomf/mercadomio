import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../services/config_service.dart';
import '../services/category_service.dart';
import '../services/cart_controller.dart';
import '../models/product.dart';

class ProductListingWidget extends StatefulWidget {
  const ProductListingWidget({super.key});

  @override
  State<ProductListingWidget> createState() => ProductListingWidgetState();
}

class ProductListingWidgetState extends State<ProductListingWidget> {
  final RxList<Product> _products = <Product>[].obs;
  final RxString _viewMode = 'card'.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxInt _totalProducts = 0.obs;
  final RxInt _filteredProducts = 0.obs;
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final categoryService = Get.find<CategoryService>();
      await categoryService.getCategories();
      _fetchProducts();
    } catch (e) {
      print('[ERROR] Failed to initialize data: $e');
      _errorMessage.value = 'Failed to load categories';
      _isLoading.value = false;
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        _currentPage = 1;
        _hasMore = true;
        _products.clear();
        
        // Always fetch total count when starting fresh
        await _fetchTotalCount();
      }
      
      _isLoading.value = true;
      _errorMessage.value = '';
      final configService = Get.find<ConfigService>();
      final categoryService = Get.find<CategoryService>();
      
      final apiUrl = await configService.getApiUrl();
      
      // Build the URL with proper category filtering using category names
      final uri = categoryService.selectedCategories.isEmpty
        ? Uri.parse('$apiUrl/api/products?page=$_currentPage&limit=$_itemsPerPage')
        : Uri.parse('$apiUrl/api/products?page=$_currentPage&limit=$_itemsPerPage&category=${Uri.encodeComponent(categoryService.selectedCategoryNames.join(','))}');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Expected object but got ${decoded.runtimeType}');
        }
        
        final List<dynamic> data = decoded['data'] ?? [];
        final newProducts = data.map((json) => Product.fromJson(json)).toList();
        final responseTotal = decoded['total'] ?? newProducts.length;
        
        // Update counts appropriately
        if (categoryService.selectedCategories.isEmpty) {
          // When no categories selected, this is the total
          _totalProducts.value = responseTotal;
        } else {
          // When categories are selected, this is the filtered count
          _filteredProducts.value = responseTotal;
        }
        
        // Always fetch the actual total count when categories are selected
        if (categoryService.selectedCategories.isNotEmpty && !loadMore) {
          await _fetchTotalCount();
        }
        
        if (loadMore) {
          _products.addAll(newProducts);
        } else {
          _products.value = newProducts;
        }
        _hasMore = newProducts.length == _itemsPerPage;
        _currentPage++;
      } else {
        _errorMessage.value = 'Failed to load products (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch products: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchTotalCount() async {
    try {
      final configService = Get.find<ConfigService>();
      final apiUrl = await configService.getApiUrl();
      
      // Fetch total count without any filters
      final uri = Uri.parse('$apiUrl/api/products?page=1&limit=1');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        _totalProducts.value = decoded['total'] ?? 0;
      }
    } catch (e) {
      print('Error fetching total count: $e');
    }
  }

  Future<void> searchProducts(String query) async {
    try {
      _isLoading.value = true;
      final configService = Get.find<ConfigService>();
      final categoryService = Get.find<CategoryService>();
      final apiUrl = await configService.getApiUrl();
      
      // Build search URL with category filtering using names
      final uri = categoryService.selectedCategoryNames.isEmpty
        ? Uri.parse('$apiUrl/api/products/search?q=$query')
        : Uri.parse('$apiUrl/api/products/search?q=$query&category=${Uri.encodeComponent(categoryService.selectedCategoryNames.join(','))}');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final filteredProducts = data.map((json) => Product.fromJson(json)).toList();
        _products.value = filteredProducts;
        _products.refresh();
        
        // Update filtered count for search results
        _filteredProducts.value = filteredProducts.length;
        
        // Ensure we have the total count
        await _fetchTotalCount();
      }
    } catch (e) {
      Get.snackbar('Error', 'Search failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshProducts() async {
    await _fetchProducts();
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8.0),
              ),
              child: product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image, size: 40)),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('\$${product.basePrice.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _addToCart(product),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      width: 80,
                      height: 80,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.image, size: 24),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 24),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.basePrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () => _addToCart(product),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    final cartController = Get.find<CartController>();
    cartController.addToCart(
      productId: product.id,
      quantity: 1,
    );
    Get.snackbar(
      'Added to Cart',
      '${product.name} was added to your cart',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryService = Get.find<CategoryService>();
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                searchProducts(query.trim());
              } else {
                _fetchProducts();
              }
            },
          ),
        ),
        
        // Category filter chips
        Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              if (categoryService.selectedCategories.isNotEmpty)
                FilterChip(
                  label: const Text('Clear all'),
                  onSelected: (_) {
                    categoryService.clearSelectedCategories();
                    _fetchProducts();
                  },
                ),
              ...categoryService.categories.map((cat) => FilterChip(
                label: Text(cat.name),
                selected: categoryService.selectedCategories.contains(cat.id),
                onSelected: (selected) {
                  selected
                    ? categoryService.addSelectedCategory(cat.id, cat.name)
                    : categoryService.removeSelectedCategory(cat.id);
                  _fetchProducts();
                },
              )),
            ],
          ),
        )),

        // View mode toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.grid_view,
                  color: _viewMode.value == 'card' ? Colors.deepPurple : Colors.grey,
                ),
                onPressed: () => _viewMode.value = 'card',
              ),
              IconButton(
                icon: Icon(
                  Icons.list,
                  color: _viewMode.value == 'list' ? Colors.deepPurple : Colors.grey,
                ),
                onPressed: () => _viewMode.value = 'list',
              ),
            ],
          )),
        ),

        // Product count
        Obx(() {
          final categoryService = Get.find<CategoryService>();
          final filteredCount = categoryService.selectedCategories.isEmpty 
            ? _totalProducts.value 
            : _filteredProducts.value;
          final totalCount = _totalProducts.value;
          
          final countText = categoryService.selectedCategories.isEmpty
            ? '$totalCount products'
            : '$filteredCount filtered products (of $totalCount)';
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              countText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          );
        }),

        // Product list
        Expanded(
          child: Obx(() {
            if (_isLoading.value && !_hasMore) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_errorMessage.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage.value),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchProducts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (_products.isEmpty) {
              return const Center(child: Text('No products available'));
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (scroll) {
                if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent && 
                    _hasMore && 
                    !_isLoading.value) {
                  _fetchProducts(loadMore: true);
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _refreshProducts,
                child: _viewMode.value == 'card' 
                  ? GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        crossAxisSpacing: 6.0,
                        mainAxisSpacing: 6.0,
                        childAspectRatio: 0.55,
                      ),
                      itemCount: _products.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildProductCard(_products[index]);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      itemCount: _products.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildProductListItem(_products[index]);
                      },
                    ),
              ),
            );
          }),
        ),
      ],
    );
  }
}