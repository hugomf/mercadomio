import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/category_service.dart';
import '../services/category_events.dart';
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
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${discount.round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onError,
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
                            // Stitch shows the unit inline on regular-priced
                            // cards: '$85.00 / kg'.
                            if (discount == null && unit != null)
                              Text(
                                '/ $unit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Stitch add button: filled primary when the product is
                      // discounted, primary-container otherwise.
                      Material(
                        color: discount != null
                            ? colorScheme.primary
                            : colorScheme.primaryContainer,
                        shape: CircleBorder(
                          side: discount != null
                              ? BorderSide.none
                              : BorderSide(
                                  color: colorScheme.primary.withValues(
                                      alpha: 0.2),
                                ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: discount != null
                                ? colorScheme.onPrimary
                                : colorScheme.onPrimaryContainer,
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

  StreamSubscription<CategorySelectionEvent>? _categorySub;

  @override
  void initState() {
    super.initState();
    // Refresh results whenever categories change anywhere in the app
    // (e.g. the storefront tiles), keeping them in sync with the sidebar.
    _categorySub = CategoryEventBus.stream.listen((_) {
      _fetchProducts();
    });
    // Ensure products are loaded when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    _searchController.dispose();
    super.dispose();
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
          // Category changes are handled by the event bus listener in
          // initState (selection mutations publish to CategoryEventBus).
          onSelectionChanged: () {},
        ),

        // Category breadcrumbs
        CategoryBreadcrumbs(
          onBreadcrumbTap: () {},
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

        const SizedBox(width: 24),

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

              _buildDesktopPageHeader(),

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

  /// Stitch-style page header: breadcrumb, h1 title, product count and the
  /// removable "applied filters" chips. Only rendered on desktop.
  Widget _buildDesktopPageHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = _getPadding(context, base: 16);

    return GetBuilder<CategoryService>(
      builder: (categoryService) {
        final hasActiveFilters =
            categoryService.selectedCategories.isNotEmpty &&
                !categoryService.isAllSelected();
        final searchTerm = _searchText.value.trim();
        final activeLabel = hasActiveFilters &&
                categoryService.selectedCategoryNames.isNotEmpty
            ? categoryService.selectedCategoryNames.last
            : 'Productos';
        final count = hasActiveFilters || searchTerm.isNotEmpty
            ? _filteredProducts.value
            : _totalProducts.value;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: _getPadding(context, base: 4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb: Inicio > Categorías > active category
              Row(
                children: [
                  Text(
                    'Inicio',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                    Text(
                      activeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // h1 title + product count
              Text(
                activeLabel,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count productos disponibles',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              // Applied filters: removable chips + clear-all
              if (hasActiveFilters || searchTerm.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildAppliedFilterChips(categoryService),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Removable primary-container chips for each active filter plus a
  /// "Limpiar filtros" link (Stitch "Applied Filters" row).
  Widget _buildAppliedFilterChips(CategoryService categoryService) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchTerm = _searchText.value.trim();
    final hasAnyFilter = categoryService.selectedCategoryNames.isNotEmpty ||
        searchTerm.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // One chip per selected category (keeps filter order).
        for (var i = 0; i < categoryService.selectedCategoryNames.length; i++)
          Chip(
            label: Text(
              categoryService.selectedCategoryNames[i],
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: colorScheme.primaryContainer,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
            deleteIcon: Icon(
              Icons.close,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
            onDeleted: () {
              categoryService.removeCategoriesFromIndex(i);
            },
          ),
        // A chip reflecting the active search term.
        if (searchTerm.isNotEmpty)
          Chip(
            label: Text(
              '“$searchTerm”',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: colorScheme.primaryContainer,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
            deleteIcon: Icon(
              Icons.close,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
            onDeleted: () {
              _searchController.clear();
              _searchText.value = '';
              _debounceTimer?.cancel();
              _fetchProducts();
            },
          ),
        if (hasAnyFilter)
          TextButton(
            onPressed: () {
              categoryService.clearSelectedCategories();
              _searchController.clear();
              _searchText.value = '';
              _debounceTimer?.cancel();
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Limpiar filtros'),
          ),
      ],
    );
  }

  Widget _buildCategorySidebar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.surfaceContainer),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                  const SizedBox(height: 4),
                  _buildSidebarItem(
                    label: 'Todos',
                    selected: isAllSelected,
                    onTap: () {
                      categoryService.addSelectedCategory(
                        CategoryService.allCategoriesId,
                        CategoryService.allCategoriesName,
                      );
                    },
                  ),
                  ...categoryService.categories.map((category) {
                    final isSelected = categoryService.selectedCategories.contains(category.id);
                    return _buildSidebarItem(
                      label: category.name,
                      selected: isSelected,
                      onTap: () {
                        categoryService.addSelectedCategory(category.id, category.name);
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Icon(
            Icons.expand_less,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: selected ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final totalPages = (_filteredProducts.value / _itemsPerPage).ceil().clamp(1, 1 << 20);
    final currentPage = _currentPage - 1; // _currentPage is 1-based.
    if (totalPages <= 1 && !_hasMore) {
      return const SizedBox.shrink();
    }

    // Page numbers to show around the current one (with ellipsis on both
    // sides when the range is large), matching the Stitch pagination row.
    final int window = 5;
    final int start = totalPages <= window
        ? 1
        : (currentPage - (window ~/ 2)).clamp(1, totalPages - window + 1);
    final int end = totalPages <= window
        ? totalPages
        : (start + window - 1).clamp(1, totalPages);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getPadding(context, base: 16),
        vertical: _getPadding(context, base: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, size: _getIconSize(context, base: 22)),
            color: colorScheme.onSurfaceVariant,
            onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
          ),
          if (start > 1) ...[
            _buildPageNumber(1, currentPage, colorScheme),
            if (start > 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: _getPadding(context, base: 4)),
                child: Text(
                  '...',
                  style: TextStyle(
                    fontSize: _getFontSize(context, base: 14),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          for (var page = start; page <= end; page++)
            _buildPageNumber(page, currentPage, colorScheme),
          if (end < totalPages) ...[
            if (end < totalPages - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: _getPadding(context, base: 4)),
                child: Text(
                  '...',
                  style: TextStyle(
                    fontSize: _getFontSize(context, base: 14),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            _buildPageNumber(totalPages, currentPage, colorScheme),
          ],
          IconButton(
            icon: Icon(Icons.chevron_right, size: _getIconSize(context, base: 22)),
            color: colorScheme.onSurfaceVariant,
            onPressed: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  /// Single square page-number button (active = filled primary).
  Widget _buildPageNumber(int page, int currentPage, ColorScheme colorScheme) {
    final selected = page == currentPage;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _getPadding(context, base: 2)),
      child: InkWell(
        onTap: selected ? null : () => _goToPage(page),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: _getFontSize(context, base: 14),
              fontWeight: selected ? FontWeight.bold : FontWeight.w400,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
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
