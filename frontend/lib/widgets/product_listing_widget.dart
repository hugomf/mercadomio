import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:responsive_framework/responsive_framework.dart';
import '../services/category_service.dart';
import '../services/config_service.dart';
import '../services/cart_controller.dart';
import '../widgets/category_selector.dart';
import '../widgets/category_breadcrumbs.dart';
import '../widgets/product_search_controls.dart';
<<<<<<< HEAD
import '../widgets/product_detail_screen.dart';
=======
import '../widgets/product_card.dart';
import '../widgets/product_list_item.dart';
>>>>>>> origin/main
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
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchText = ''.obs;
  Timer? _debounceTimer;
  final RxString _sortBy = 'name'.obs;
  final RxBool _sortAscending = true.obs;

  Future<void> _fetchProducts({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        _currentPage = 1;
        _hasMore = true;
        _products.clear();
        await _fetchTotalCount();
      }
      
      _isLoading.value = true;
      _errorMessage.value = '';
      
      final configService = Get.find<ConfigService>();
      final categoryService = Get.find<CategoryService>();
      final searchQuery = _searchText.value.trim();
      final apiUrl = await configService.getApiUrl();
      
      final response = await categoryService.getFilteredProducts(
        apiUrl: apiUrl,
        page: _currentPage,
        limit: _itemsPerPage,
        searchQuery: searchQuery,
        sortBy: _sortBy.value,
        sortAscending: _sortAscending.value,
      );
      
      final newProducts = response['products'] as List<Product>;
      final totalCount = response['total'] as int;
      
      final hasSearch = searchQuery.isNotEmpty;
      final hasCategoryFilter = categoryService.selectedCategories.isNotEmpty &&
                               !categoryService.isAllSelected();
      
      if (hasSearch || hasCategoryFilter) {
        _filteredProducts.value = totalCount;
        if (!loadMore) await _fetchTotalCount();
      } else {
        _totalProducts.value = totalCount;
        _filteredProducts.value = totalCount;
      }
      
      if (loadMore) {
        _products.addAll(newProducts);
      } else {
        _products.value = newProducts;
      }
      
      _hasMore = newProducts.length == _itemsPerPage;
      _currentPage++;
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
      final uri = Uri.parse('$apiUrl/api/products?page=1&limit=1');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        _totalProducts.value = decoded['total'] ?? 0;
      }
    } catch (e) {
      // Error handled by UI display
    }
  }

  Future<void> _refreshProducts() async {
    await _fetchProducts();
  }

  Future<void> searchProducts(String query) async {
    _searchController.text = query;
    _searchText.value = query;
    await _fetchProducts();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchText.value = query;
      _fetchProducts();
    });
  }

  // Responsive design system
  double _getResponsiveValue(BuildContext context,
      {required double mobile, required double tablet, required double desktop, double? fourK}) {
    if (ResponsiveBreakpoints.of(context).isMobile) return mobile;
    if (ResponsiveBreakpoints.of(context).isTablet) return tablet;
    if (ResponsiveBreakpoints.of(context).isDesktop) return desktop;
    return fourK ?? desktop;
  }

  int _getCrossAxisCount(BuildContext context) {
    return _getResponsiveValue(context,
      mobile: 2,
      tablet: 3,
      desktop: MediaQuery.of(context).size.width > 1400 ? 5 : 4,
      fourK: 6,
    ).toInt();
  }

  double _getAspectRatio(BuildContext context) {
    return _getResponsiveValue(context,
      mobile: 0.65,
      tablet: 0.7,
      desktop: 0.75,
      fourK: 0.8,
    );
  }

  double _getSpacing(BuildContext context) {
    return _getResponsiveValue(context,
      mobile: 4,
      tablet: 6,
      desktop: 8,
      fourK: 12,
    );
  }

  double _getFontSize(BuildContext context, {required double base}) {
    return _getResponsiveValue(context,
      mobile: base * 0.9,
      tablet: base,
      desktop: base * 1.2,
      fourK: base * 1.2,
    );
  }

  double _getIconSize(BuildContext context, {required double base}) {
    return _getResponsiveValue(context,
      mobile: base * 0.9,
      tablet: base,
      desktop: base * 1.4,
      fourK: base * 1.2,
    );
  }

  double _getPadding(BuildContext context, {required double base}) {
    return _getResponsiveValue(context,
      mobile: base * 0.8,
      tablet: base,
      desktop: base * 1.2,
      fourK: base * 1.5,
    );
  }

  double _getCardHeight(BuildContext context) {
    return _getResponsiveValue(context,
      mobile: 280,
      tablet: 320,
      desktop: 300,
      fourK: 400,
    );
  }

  double _getImageHeight(BuildContext context) {
    return _getResponsiveValue(context,
      mobile: 0.65,
      tablet: 0.62,
      desktop: 0.8,
      fourK: 0.58,
    );
  }

  Widget _buildProductCard(Product product) {
<<<<<<< HEAD
    final cardHeight = _getCardHeight(context);
    final imageHeight = cardHeight * _getImageHeight(context);
    final padding = _getPadding(context, base: 8);
    final fontSize = _getFontSize(context, base: 14);
    final iconSize = _getIconSize(context, base: 20);
    final starSize = _getIconSize(context, base: 14);

    return SizedBox(
      height: cardHeight,
      child: GestureDetector(
        onTap: () => _navigateToProductDetail(product.id),
        child: Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: SizedBox(
                        width: _getIconSize(context, base: 24),
                        height: _getIconSize(context, base: 24),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: Icon(
                      Icons.image,
                      size: _getIconSize(context, base: 48),
                      color: Colors.grey,
                    ),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(_getPadding(context, base: 8)),
                      bottomRight: Radius.circular(_getPadding(context, base: 8)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${product.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: fontSize * 1.15,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  Icons.star,
                                  size: starSize,
                                  color: index < (product.averageRating > 0 ? product.averageRating.floor() : 4)
                                      ? Colors.amber
                                      : Colors.grey,
                                );
                              }),
                              SizedBox(width: _getPadding(context, base: 4)),
                              Text(
                                product.averageRating > 0 ? product.averageRating.toStringAsFixed(1) : '4.0',
                                style: TextStyle(
                                  fontSize: fontSize * 0.85,
                                  color: Colors.grey,
                                ),
                              ),
                              if (product.reviewCount > 0) ...[
                                SizedBox(width: _getPadding(context, base: 4)),
                                Text(
                                  '(${product.reviewCount})',
                                  style: TextStyle(
                                    fontSize: fontSize * 0.8,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              size: iconSize,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () => _addToCart(product),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
=======
    return ProductCard(
      product: product,
      onAddToCart: () => _addToCart(product),
      cardHeight: _getCardHeight(context),
      imageHeightRatio: _getImageHeight(context),
      padding: _getPadding(context, base: 8),
      fontSize: _getFontSize(context, base: 14),
      iconSize: _getIconSize(context, base: 20),
      starSize: _getIconSize(context, base: 14),
>>>>>>> origin/main
    );
  }

  Widget _buildProductListItem(Product product) {
    final imageSize = _getResponsiveValue(context,
      mobile: 60,
      tablet: 70,
      desktop: 80,
      fourK: 90,
    );
    
    return ProductListItem(
      product: product,
      onAddToCart: () => _addToCart(product),
      imageSize: imageSize,
      padding: _getPadding(context, base: 8),
      fontSize: _getFontSize(context, base: 14),
      iconSize: _getIconSize(context, base: 24),
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
      duration: const Duration(milliseconds: 800),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: 8,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      animationDuration: const Duration(milliseconds: 200),
    );
  }

  void _navigateToProductDetail(String productId) {
    Get.to(() => ProductDetailScreen(productId: productId));
  }

  @override
  void initState() {
    super.initState();
    // Ensure products are loaded when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Search bar and controls
        ProductSearchControls(
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onClearSearch: () {
            _searchController.clear();
            _searchText.value = '';
            _debounceTimer?.cancel();
            _filteredProducts.value = 0;
            _fetchProducts();
          },
          onSortSelected: (value) {
            final parts = value.split('_');
            _sortBy.value = parts[0];
            _sortAscending.value = parts[1] == 'asc';
            _fetchProducts();
          },
          onViewModeChanged: (mode) => _viewMode.value = mode,
          currentViewMode: _viewMode.value,
          searchText: _searchText,
        ),
        
        CategorySelector(
          onSelectionChanged: _fetchProducts,
        ),

        // Category breadcrumbs
        CategoryBreadcrumbs(
          onBreadcrumbTap: _fetchProducts,
        ),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _getPadding(context, base: 16),
            vertical: _getPadding(context, base: 4),
          ),
          child: GetBuilder<CategoryService>(
            builder: (categoryService) {
              final hasActiveFilters = categoryService.selectedCategories.isNotEmpty ||
                                    _searchText.value.trim().isNotEmpty;
              return Text(
                hasActiveFilters && !categoryService.isAllSelected()
                  ? '${_filteredProducts.value} of ${_totalProducts.value} products'
                  : '${_totalProducts.value} products',
                style: TextStyle(
                  fontSize: _getFontSize(context, base: 14),
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                if (_isLoading.value && !_hasMore) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_errorMessage.value.isNotEmpty) {
                  return Center(child: Text(_errorMessage.value));
                }
                if (_products.isEmpty) {
                  return const Center(child: Text('No products available'));
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent &&
                        _hasMore && !_isLoading.value) {
                      _fetchProducts(loadMore: true);
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: _refreshProducts,
                    child: _viewMode.value == 'card'
                      ? GridView.builder(
                          padding: EdgeInsets.all(_getPadding(context, base: 8)),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            childAspectRatio: _getAspectRatio(context),
                            crossAxisSpacing: _getSpacing(context),
                            mainAxisSpacing: _getSpacing(context),
                          ),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return Center(
                                child: SizedBox(
                                  width: _getIconSize(context, base: 24),
                                  height: _getIconSize(context, base: 24),
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            return _buildProductCard(_products[index]);
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: _getPadding(context, base: 8),
                            vertical: _getPadding(context, base: 4),
                          ),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return Center(
                                child: SizedBox(
                                  width: _getIconSize(context, base: 24),
                                  height: _getIconSize(context, base: 24),
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            return _buildProductListItem(_products[index]);
                          },
                        ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    // Use same layout as mobile but with enhanced grid for larger screens
    return Column(
      children: [
        // Search bar and controls
        ProductSearchControls(
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onClearSearch: () {
            _searchController.clear();
            _searchText.value = '';
            _debounceTimer?.cancel();
            _filteredProducts.value = 0;
            _fetchProducts();
          },
          onSortSelected: (value) {
            final parts = value.split('_');
            _sortBy.value = parts[0];
            _sortAscending.value = parts[1] == 'asc';
            _fetchProducts();
          },
          onViewModeChanged: (mode) => _viewMode.value = mode,
          currentViewMode: _viewMode.value,
          searchText: _searchText,
        ),
        
        CategorySelector(
          onSelectionChanged: _fetchProducts,
        ),

        // Category breadcrumbs
        CategoryBreadcrumbs(
          onBreadcrumbTap: _fetchProducts,
        ),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _getPadding(context, base: 16),
            vertical: _getPadding(context, base: 8),
          ),
          child: GetBuilder<CategoryService>(
            builder: (categoryService) {
              final hasActiveFilters = categoryService.selectedCategories.isNotEmpty ||
                                    _searchText.value.trim().isNotEmpty;
              return Text(
                hasActiveFilters && !categoryService.isAllSelected()
                  ? '${_filteredProducts.value} of ${_totalProducts.value} products'
                  : '${_totalProducts.value} products',
                style: TextStyle(
                  fontSize: _getFontSize(context, base: 16),
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                if (_isLoading.value && !_hasMore) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_errorMessage.value.isNotEmpty) {
                  return Center(child: Text(_errorMessage.value));
                }
                if (_products.isEmpty) {
                  return const Center(child: Text('No products available'));
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent &&
                        _hasMore && !_isLoading.value) {
                      _fetchProducts(loadMore: true);
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: _refreshProducts,
                    child: _viewMode.value == 'card'
                      ? GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            childAspectRatio: _getAspectRatio(context),
                            crossAxisSpacing: _getSpacing(context),
                            mainAxisSpacing: _getSpacing(context),
                          ),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return _buildProductCard(_products[index]);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return _buildProductListItem(_products[index]);
                          },
                        ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800; // Lower threshold for testing
        
        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }
}