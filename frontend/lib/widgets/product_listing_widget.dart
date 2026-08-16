import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/category_service.dart';
import '../services/config_service.dart';
import '../services/cart_controller.dart';
import '../widgets/category_selector.dart';
import '../widgets/category_breadcrumbs.dart';
import '../widgets/product_search_controls.dart';
import '../widgets/product_detail_screen.dart';
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

  Future<void> _fetchProducts({bool loadMore = false, int? page}) async {
    try {
      if (!loadMore) {
        _currentPage = page ?? 1;
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
      _errorMessage.value = 'Error al cargar productos: ${e.toString()}';
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
      desktop: MediaQuery.of(context).size.width > 1400 ? 4 : 3,
      fourK: 5,
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

  Widget _buildProductCard(Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardHeight = _getCardHeight(context);
    final padding = _getPadding(context, base: 8);
    final fontSize = _getFontSize(context, base: 14);
    final iconSize = _getIconSize(context, base: 20);
    final starSize = _getIconSize(context, base: 14);

    return SizedBox(
      height: cardHeight,
      child: GestureDetector(
        onTap: () => _navigateToProductDetail(product.id),
child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                // Flexible image: shrinks when the grid tile is short so the
                // text block below always fits without overflowing.
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerHigh,
                        child: Center(
                          child: SizedBox(
                            width: _getIconSize(context, base: 24),
                            height: _getIconSize(context, base: 24),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.image,
                          size: _getIconSize(context, base: 48),
                          color: colorScheme.outline,
                        ),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${product.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: fontSize * 1.15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    Icons.star,
                                    size: starSize,
                                    color: index < (product.averageRating > 0 ? product.averageRating.floor() : 4)
                                        ? Colors.amber
                                        : colorScheme.outlineVariant,
                                  );
                                }),
                                SizedBox(width: _getPadding(context, base: 4)),
                                Flexible(
                                  child: Text(
                                    product.averageRating > 0 ? product.averageRating.toStringAsFixed(1) : '4.0',
                                    style: TextStyle(
                                      fontSize: fontSize * 0.85,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (product.reviewCount > 0) ...[
                                  SizedBox(width: _getPadding(context, base: 4)),
                                  Flexible(
                                    child: Text(
                                      '(${product.reviewCount})',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.8,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              size: iconSize,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            onPressed: () => _addToCart(product),
                            padding: EdgeInsets.all(_getPadding(context, base: 6)),
                            constraints: const BoxConstraints(),
                            style: _cartButtonStyle(colorScheme),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageSize = _getResponsiveValue(context,
      mobile: 60,
      tablet: 70,
      desktop: 80,
      fourK: 90,
    );
    final padding = _getPadding(context, base: 8);
    final fontSize = _getFontSize(context, base: 14);
    final iconSize = _getIconSize(context, base: 24);

    return Card(
      margin: EdgeInsets.only(bottom: padding),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_getPadding(context, base: 4)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHigh,
                  width: imageSize,
                  height: imageSize,
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHigh,
                  width: imageSize,
                  height: imageSize,
                  child: Icon(Icons.image, size: imageSize * 0.6, color: colorScheme.outline),
                ),
              ),
            ),
            SizedBox(width: _getPadding(context, base: 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _getPadding(context, base: 4)),
                  Text(
                    '\$${product.basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              icon: Icon(
                Icons.add_shopping_cart,
                size: iconSize,
                color: colorScheme.onPrimaryContainer,
              ),
              onPressed: () => _addToCart(product),
              style: _cartButtonStyle(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    final cartController = Get.find<CartController>();
    final colorScheme = Get.theme.colorScheme;
    // Capture the messenger before the async gap: `Get.snackbar` needs an
    // Overlay ancestor and can crash when called after an `await`.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await cartController.addToCart(
        productId: product.id,
        quantity: 1,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('${product.name} se agregó a tu carrito'),
          duration: const Duration(milliseconds: 1200),
          backgroundColor: colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          closeIconColor: colorScheme.onPrimary,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo agregar. Error: $e'),
          duration: const Duration(milliseconds: 2500),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          closeIconColor: colorScheme.onError,
        ),
      );
    }
  }

  void _navigateToProductDetail(String productId) {
    Get.to(() => ProductDetailScreen(productId: productId));
  }

  /// Button style for the add-to-cart icon with visible hover/press feedback.
  ButtonStyle _cartButtonStyle(ColorScheme colorScheme) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.surfaceContainerHighest;
        }
        return colorScheme.primaryContainer;
      }),
      // Overlay gives hover (light) and pressed (stronger) feedback so the
      // button visibly reacts instead of looking static.
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.onPrimaryContainer.withValues(alpha: 0.24);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.onPrimaryContainer.withValues(alpha: 0.10);
        }
        return Colors.transparent;
      }),
    );
  }

  /// Unit label (e.g. "1 kg") resolved by the backend pricing engine and
  /// attached to the product's customAttributes on every catalog read.
  /// Returns null when the product has no unit.
  String? _productUnit(Product product) {
    final attrs = product.customAttributes;
    final raw = attrs?['unit'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  /// Discount percent computed by the backend pricing engine from the
  /// difference between base price and resolved (schedule+set) price.
  /// Only present when a real discount applies.
  double? _productDiscount(Product product) {
    final attrs = product.customAttributes;
    final raw = attrs?['discountPercent'];
    if (raw is num && raw > 0) return raw.toDouble();
    return null;
  }

  Widget _buildDesktopProductCard(Product product) {
    final colorScheme = Theme.of(context).colorScheme;
    final unit = _productUnit(product);
    final discount = _productDiscount(product);

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product.id),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.surfaceContainerHighest),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image: flexible so the body below always keeps its natural height
            // (square tiles on narrow columns can't fit a full square image
            // plus the text block).
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainer,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainer,
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  if (discount != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${discount.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => Get.snackbar(
                          'Favoritos',
                          '${product.name} se agregó a tu lista de deseos',
                          backgroundColor: colorScheme.tertiary,
                          colorText: colorScheme.onTertiary,
                          margin: const EdgeInsets.all(20),
                          borderRadius: 8,
                          duration: const Duration(milliseconds: 1200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.category != null) ...[
                    Text(
                      product.category!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (discount != null) ...[
                              Text(
                                '\$${product.basePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 1),
                            ],
                            Text(
                              '\$${_discountedPrice(product).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: colorScheme.primaryContainer,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () => _addToCart(product),
                          tooltip: 'Agregar al carrito',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _discountedPrice(Product product) {
    final discount = _productDiscount(product);
    if (discount == null) return product.basePrice;
    return product.basePrice * (1 - discount / 100);
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
                  ? '${_filteredProducts.value} de ${_totalProducts.value} productos'
                  : '${_totalProducts.value} productos',
                style: TextStyle(
                  fontSize: _getFontSize(context, base: 14),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  return const Center(child: Text('No hay productos disponibles'));
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persistent category sidebar
        _buildCategorySidebar(),

        // Main content column: toolbar, count, grid, pagination
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _getPadding(context, base: 16),
                  _getPadding(context, base: 12),
                  _getPadding(context, base: 16),
                  0,
                ),
                child: ProductSearchControls(
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
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _getPadding(context, base: 16),
                  vertical: _getPadding(context, base: 4),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CategoryBreadcrumbs(
                    onBreadcrumbTap: _fetchProducts,
                  ),
                ),
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
                        ? '${_filteredProducts.value} de ${_totalProducts.value} productos'
                        : '${_totalProducts.value} productos disponibles',
                      style: TextStyle(
                        fontSize: _getFontSize(context, base: 15),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),

              // Responsive product grid with bottom pagination (desktop)
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
                        return const Center(child: Text('No hay productos disponibles'));
                      }

                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 860 ? 3 : 2;

                      return RefreshIndicator(
                        onRefresh: _refreshProducts,
                        child: _viewMode.value == 'card'
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                return _buildDesktopProductCard(_products[index]);
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildProductListItem(_products[index]),
                                );
                              },
                            ),
                      );
                    });
                  },
                ),
              ),

              _buildPaginationBar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GetBuilder<CategoryService>(
            builder: (categoryService) {
              final isAllSelected = categoryService.isAllSelected();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebarHeader('Categorías'),
                  _buildSidebarItem(
                    label: 'Todos',
                    selected: isAllSelected,
                    onTap: () {
                      categoryService.addSelectedCategory(
                        CategoryService.allCategoriesId,
                        CategoryService.allCategoriesName,
                      );
                      _fetchProducts();
                    },
                  ),
                  ...categoryService.categories.map((category) {
                    final isSelected = categoryService.selectedCategories.contains(category.id);
                    return _buildSidebarItem(
                      label: category.name,
                      selected: isSelected,
                      onTap: () {
                        categoryService.addSelectedCategory(category.id, category.name);
                        _fetchProducts();
                      },
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _getPadding(context, base: 16),
        _getPadding(context, base: 8),
        _getPadding(context, base: 16),
        _getPadding(context, base: 8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: _getFontSize(context, base: 16),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = _getPadding(context, base: 12);

    return Material(
      color: selected ? colorScheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.category_outlined,
                size: _getIconSize(context, base: 20),
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: _getPadding(context, base: 12)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _getFontSize(context, base: 15),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                    color: selected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final totalPages = (_filteredProducts.value / _itemsPerPage).ceil().clamp(1, 1 << 20);
    final currentPage = _currentPage - 1;
    if (totalPages <= 1 && !_hasMore) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getPadding(context, base: 16),
        vertical: _getPadding(context, base: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, size: _getIconSize(context, base: 22)),
            onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _getPadding(context, base: 8)),
            child: Text(
              'Página $currentPage de $totalPages',
              style: TextStyle(
                fontSize: _getFontSize(context, base: 14),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, size: _getIconSize(context, base: 22)),
            onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _goToPage(int page) async {
    if (page < 1) return;
    _currentPage = page;
    await _fetchProducts(page: page);
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
