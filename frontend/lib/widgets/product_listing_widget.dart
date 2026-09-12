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
import '../widgets/product_detail_screen.dart';
import '../widgets/cart_screen.dart';
import '../models/product.dart';

class ProductListingWidget extends StatefulWidget {
  const ProductListingWidget({
    super.key,
    /// When false, the desktop sidebar's "Categorías" section is hidden.
    /// Use this when the widget lives in a home screen that already shows
    /// category tiles (e.g. the storefront hero) to avoid duplicating
    /// category navigation.
    this.showCategorySidebar = true,
    /// When true, renders a content-sized product grid (no sidebar, no
    /// bounded-height layout) suitable for embedding inside the free-scrolling
    /// storefront home page, mirroring the single-scroll storefront mock.
    this.embeddedScroll = false,
  });

  /// When false, the desktop sidebar's "Categorías" section is hidden.
  final bool showCategorySidebar;

  /// When true, renders a content-sized grid inside the page scroll instead
  /// of the bounded-height desktop layout.
  final bool embeddedScroll;

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

  // Price range filter (desktop sidebar)
  double _priceMin = 0.0;
  double _priceMax = 500.0;
  double _rangeMin = 10.0;
  double _rangeMax = 500.0;

  // Mobile pagination (replaces infinite scroll)
  int get _totalPages =>
      (_filteredProducts.value / _itemsPerPage).ceil().clamp(1, 1 << 20);

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
        minPrice: _priceMin.isFinite ? _priceMin : null,
        maxPrice: _priceMax.isFinite ? _priceMax : null,
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
      {required double mobile,
      required double tablet,
      required double desktop,
      double? fourK}) {
    if (ResponsiveBreakpoints.of(context).isMobile) return mobile;
    if (ResponsiveBreakpoints.of(context).isTablet) return tablet;
    if (ResponsiveBreakpoints.of(context).isDesktop) return desktop;
    return fourK ?? desktop;
  }

  int _getCrossAxisCount(BuildContext context) {
    return _getResponsiveValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: MediaQuery.of(context).size.width > 1400 ? 4 : 3,
      fourK: 5,
    ).toInt();
  }

  double _getAspectRatio(BuildContext context) {
    return _getResponsiveValue(
      context,
      mobile: 0.65,
      tablet: 0.7,
      desktop: 0.75,
      fourK: 0.8,
    );
  }

  double _getSpacing(BuildContext context) {
    return _getResponsiveValue(
      context,
      mobile: 4,
      tablet: 6,
      desktop: 8,
      fourK: 12,
    );
  }

  double _getFontSize(BuildContext context, {required double base}) {
    return _getResponsiveValue(
      context,
      mobile: base * 0.9,
      tablet: base,
      desktop: base * 1.2,
      fourK: base * 1.2,
    );
  }

  double _getIconSize(BuildContext context, {required double base}) {
    return _getResponsiveValue(
      context,
      mobile: base * 0.9,
      tablet: base,
      desktop: base * 1.4,
      fourK: base * 1.2,
    );
  }

  double _getPadding(BuildContext context, {required double base}) {
    return _getResponsiveValue(
      context,
      mobile: base * 0.8,
      tablet: base,
      desktop: base * 1.2,
      fourK: base * 1.5,
    );
  }

  double _getCardHeight(BuildContext context) {
    return _getResponsiveValue(
      context,
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
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
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
                                  color: index <
                                          (product.averageRating > 0
                                              ? product.averageRating.floor()
                                              : 4)
                                      ? Colors.amber
                                      : colorScheme.outlineVariant,
                                );
                              }),
                              SizedBox(width: _getPadding(context, base: 4)),
                              Flexible(
                                child: Text(
                                  product.averageRating > 0
                                      ? product.averageRating.toStringAsFixed(1)
                                      : '4.0',
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
                          padding:
                              EdgeInsets.all(_getPadding(context, base: 6)),
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
    final imageSize = _getResponsiveValue(
      context,
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
              borderRadius:
                  BorderRadius.circular(_getPadding(context, base: 4)),
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
                  child: Icon(Icons.image,
                      size: imageSize * 0.6, color: colorScheme.outline),
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

  Widget _buildDesktopProductCard(Product product) {
    return _DesktopProductCard(
      product: product,
      onTap: () => _navigateToProductDetail(product.id),
      onAddToCart: () => _addToCart(product),
    );
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
        // Mobile TopAppBar (sticky): location chip + search + cart icon
        _buildMobileTopAppBar(),

        // Category selector pills
        CategorySelector(
          onSelectionChanged: () {},
        ),
        const SizedBox(height: 4),

        // Promo banner: "Envío gratis en pedidos > $500"
        _buildMobilePromoBanner(),

        // Product count + sort button section
        _buildMobileSectionHeader(),

        // Product grid with "Ver más" button at the bottom
        Expanded(
          child: _buildMobileProductGrid(),
        ),
      ],
    );
  }

  /// Sticky mobile TopAppBar: location chip in the first row, search bar
  /// in the second row, and a cart icon with badge on the right.
  Widget _buildMobileTopAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Location chip + cart icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location chip
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enviar a:',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Polanco, CDMX',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Cart icon with badge
              _buildCartBadge(colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Search bar
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar productos',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cart icon with item-count badge (matches Stitch mobile TopAppBar).
  Widget _buildCartBadge(ColorScheme colorScheme) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final itemCount = cartController.cart.value?.itemCount ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_cart,
                size: 22,
                color: colorScheme.onSurface,
              ),
              onPressed: () => Get.to(() => const CartScreen()),
            ),
            if (itemCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    itemCount > 99 ? '99+' : itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Stitch-style mobile promo banner: "Envío gratis en pedidos > $500".
  Widget _buildMobilePromoBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Decorative circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envío gratis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  'en pedidos > \$500',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSecondaryContainer
                        .withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile section header: product count (left) + sort button (right).
  Widget _buildMobileSectionHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GetBuilder<CategoryService>(
            builder: (categoryService) {
              final hasActiveFilters =
                  categoryService.selectedCategories.isNotEmpty &&
                      !categoryService.isAllSelected();
              final searchTerm = _searchText.value.trim();
              final count = hasActiveFilters || searchTerm.isNotEmpty
                  ? _filteredProducts.value
                  : _totalProducts.value;
              return Text(
                '$count productos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          // Sort button (mock shows "Filtros" but we keep sort for functionality)
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.sort,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) {
                final parts = value.split('_');
                _sortBy.value = parts[0];
                _sortAscending.value = parts[1] == 'asc';
                _fetchProducts();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'basePrice_asc',
                  child: const Text('Precio ↑ Más baratos'),
                ),
                PopupMenuItem(
                  value: 'basePrice_desc',
                  child: const Text('Precio ↓ Más caros'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile product grid with "Ver más" button at the bottom
  /// (replaces the previous infinite-scroll behaviour).
  Widget _buildMobileProductGrid() {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: SingleChildScrollView(
        child: _buildProductGridContent(),
      ),
    );
  }

  /// Shared grid + "Ver más" column used by the mobile layout (wrapped in a
  /// refreshable scroll view) and by the embedded home scroll (no wrapper).
  Widget _buildProductGridContent() {
    return Obx(() {
      if (_isLoading.value && _products.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_errorMessage.value.isNotEmpty) {
        return Center(child: Text(_errorMessage.value));
      }
      if (_products.isEmpty) {
        return const Center(child: Text('No hay productos disponibles'));
      }

      return Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(_getPadding(context, base: 8)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              childAspectRatio: _getAspectRatio(context),
              crossAxisSpacing: _getSpacing(context),
              mainAxisSpacing: _getSpacing(context),
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_products[index]);
            },
          ),
          // "Ver más" button at the bottom
          if (_hasMore && !_isLoading.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _fetchProducts(loadMore: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver más',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Loading indicator when loading more
          if (_isLoading.value && _hasMore)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    });
  }

  /// Section header for the embedded home page listing: a title in the same
  /// style as the storefront sections plus the sort control.
  Widget _buildEmbeddedSectionHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _getPadding(context, base: 8),
        32,
        _getPadding(context, base: 8),
        4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GetBuilder<CategoryService>(
            builder: (categoryService) {
              final hasActiveFilters =
                  categoryService.selectedCategories.isNotEmpty &&
                      !categoryService.isAllSelected();
              final searchTerm = _searchText.value.trim();
              final count = hasActiveFilters || searchTerm.isNotEmpty
                  ? _filteredProducts.value
                  : _totalProducts.value;
              return Text(
                hasActiveFilters || searchTerm.isNotEmpty
                    ? 'Resultados ($count)'
                    : 'Todos los productos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              );
            },
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.sort,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) {
                final parts = value.split('_');
                _sortBy.value = parts[0];
                _sortAscending.value = parts[1] == 'asc';
                _fetchProducts();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'basePrice_asc',
                  child: const Text('Precio ↑ Más baratos'),
                ),
                PopupMenuItem(
                  value: 'basePrice_desc',
                  child: const Text('Precio ↓ Más caros'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Content-sized layout used when the listing is embedded in the storefront
  /// home scroll: section header + shrink-wrap grid (no sidebar, no sticky
  /// toolbar, no bounded-height impied by Expanded).
  Widget _buildEmbeddedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEmbeddedSectionHeader(),
        _buildProductGridContent(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Builds the desktop layout: sidebar filters + product grid with toolbar,
  /// header, and bottom pagination — matching the Stitch desktop mock exactly.
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar filters (sticky, 256px wide) — matches Stitch sidebar exactly
        _buildDesktopSidebar(),
        const SizedBox(width: 24),

        // Main content area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top toolbar: search + sort + view mode
              _buildDesktopToolbar(),
              const SizedBox(height: 8),

              // Page header with breadcrumbs, title, count, applied filters
              _buildDesktopPageHeader(),

              const SizedBox(height: 8),

              // Product grid (4 columns on desktop) with bottom pagination
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
                        return const Center(
                          child: Text('No hay productos disponibles'),
                        );
                      }

                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 860
                              ? 3
                              : 2;

                      return RefreshIndicator(
                        onRefresh: _refreshProducts,
                        child: _viewMode.value == 'card'
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  return _buildDesktopProductCard(
                                      _products[index]);
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 8),
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child:
                                        _buildProductListItem(_products[index]),
                                  );
                                },
                              ),
                      );
                    });
                  },
                ),
              ),

              // Bottom pagination bar (Stitch style)
              _buildPaginationBar(),
            ],
          ),
        ),
      ],
    );
  }

  /// Desktop sidebar with collapsible sections: Categorías (checkboxes + counts)
  /// and Precio (RangeSlider + number inputs). Matches Stitch desktop sidebar.
  Widget _buildDesktopSidebar() {
    final colorScheme = Theme.of(context).colorScheme;
    final _ = colorScheme; // Used in child widgets via context

    return Container(
      width: 256,
      constraints: const BoxConstraints(maxWidth: 256),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Categorías section
            _buildDesktopSidebarSection(
              title: 'Categorías',
              icon: Icons.expand_less,
              initiallyExpanded: true,
              children: [
                GetBuilder<CategoryService>(
                  builder: (categoryService) {
                    final isAllSelected = categoryService.isAllSelected();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Todos" checkbox
                        _buildDesktopSidebarCheckbox(
                          label: 'Todos',
                          count: _totalProducts.value,
                          selected: isAllSelected,
                          onChanged: (value) {
                            if (value == true) {
                              categoryService.addSelectedCategory(
                                CategoryService.allCategoriesId,
                                CategoryService.allCategoriesName,
                              );
                              _fetchProducts();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        // Individual category checkboxes
                        ...categoryService.allCategories.map((category) {
                          final isSelected = categoryService.selectedCategories
                              .contains(category.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildDesktopSidebarCheckbox(
                              label: category.name,
                              count: _countProductsInCategory(category.id),
                              selected: isSelected,
                              onChanged: (value) {
                                categoryService.addSelectedCategory(
                                  category.id,
                                  category.name,
                                );
                                _fetchProducts();
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Precio section
            _buildDesktopSidebarSection(
              title: 'Precio',
              icon: Icons.expand_less,
              initiallyExpanded: true,
              children: _buildDesktopPriceRangeFilter(),
            ),
          ],
        ),
      ),
    );
  }

  /// Collapsible sidebar section matching Stitch design: white card, border,
  /// header with chevron, content below.
  Widget _buildDesktopSidebarSection({
    required String title,
    required IconData icon,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return StatefulBuilder(
      builder: (context, setState) {
        bool expanded = initiallyExpanded;
        return Container(
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
              // Section header with chevron
              InkWell(
                onTap: () => setState(() => expanded = !expanded),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Desktop sidebar checkbox item: checkbox + label + count badge (N).
  Widget _buildDesktopSidebarCheckbox({
    required String label,
    required int count,
    required bool selected,
    required ValueChanged<bool?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: colorScheme.outlineVariant),
              activeColor: colorScheme.primary,
              checkColor: colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0)
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Desktop price range filter: RangeSlider with editable min/max inputs below.
  List<Widget> _buildDesktopPriceRangeFilter() {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      RangeSlider(
        values: RangeValues(_rangeMin, _rangeMax),
        min: _priceMin,
        max: _priceMax,
        divisions: 50,
        labels: RangeLabels(
          '\$${_rangeMin.toStringAsFixed(0)}',
          '\$${_rangeMax.toStringAsFixed(0)}',
        ),
        onChanged: (values) {
          setState(() {
            _rangeMin = values.start;
            _rangeMax = values.end;
          });
        },
        onChangeEnd: (values) {
          _priceMin = values.start;
          _priceMax = values.end;
          _fetchProducts();
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildDesktopPriceInput(
              value: _rangeMin,
              colorScheme: colorScheme,
              onChanged: (v) => setState(() => _rangeMin = v),
              onSubmitted: () {
                _priceMin = _rangeMin;
                _fetchProducts();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _buildDesktopPriceInput(
              value: _rangeMax,
              colorScheme: colorScheme,
              onChanged: (v) => setState(() => _rangeMax = v),
              onSubmitted: () {
                _priceMax = _rangeMax;
                _fetchProducts();
              },
            ),
          ),
        ],
      ),
    ];
  }

  /// Small numeric text field with $ prefix for desktop price filter.
  Widget _buildDesktopPriceInput({
    required double value,
    required ColorScheme colorScheme,
    required ValueChanged<double> onChanged,
    required VoidCallback onSubmitted,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '\$',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextFormField(
                initialValue: value.toStringAsFixed(0),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainer,
                ),
                onChanged: (s) {
                  final parsed = double.tryParse(s);
                  if (parsed != null) onChanged(parsed);
                },
                onFieldSubmitted: (_) => onSubmitted(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop top toolbar: search bar (expanded) + sort dropdown + view mode toggle.
  Widget _buildDesktopToolbar() {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          // Search bar (expands to fill)
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.search,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Clear button (shows when text not empty)
                  Obx(() {
                    if (_searchText.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchText.value = '';
                          _debounceTimer?.cancel();
                          _fetchProducts();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Sort dropdown
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:
                    '${_sortBy.value}_${_sortAscending.value ? "asc" : "desc"}',
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                dropdownColor: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                items: const [
                  DropdownMenuItem(
                    value: 'basePrice_asc',
                    child: Text('Precio: Menor a Mayor'),
                  ),
                  DropdownMenuItem(
                    value: 'basePrice_desc',
                    child: Text('Precio: Mayor a Menor'),
                  ),
                  DropdownMenuItem(
                    value: 'name_asc',
                    child: Text('Nombre A-Z'),
                  ),
                  DropdownMenuItem(
                    value: 'name_desc',
                    child: Text('Nombre Z-A'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    final parts = value.split('_');
                    _sortBy.value = parts[0];
                    _sortAscending.value = parts[1] == 'asc';
                    _fetchProducts();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // View mode toggle (grid / list)
          Row(
            children: [
              _buildViewModeButton(
                icon: Icons.grid_view,
                selected: _viewMode.value == 'card',
                onTap: () => _viewMode.value = 'card',
              ),
              _buildViewModeButton(
                icon: Icons.view_list,
                selected: _viewMode.value == 'list',
                onTap: () => _viewMode.value = 'list',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// View mode button (grid or list) for desktop toolbar.
  Widget _buildViewModeButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
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
        final activeLabel =
            hasActiveFilters && categoryService.selectedCategoryNames.isNotEmpty
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

  Widget _buildPaginationBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final totalPages = _totalPages;
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
            icon:
                Icon(Icons.chevron_left, size: _getIconSize(context, base: 22)),
            color: colorScheme.onSurfaceVariant,
            onPressed:
                currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
          ),
          if (start > 1) ...[
            _buildPageNumber(1, currentPage, colorScheme),
            if (start > 2)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: _getPadding(context, base: 4)),
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
                padding: EdgeInsets.symmetric(
                    horizontal: _getPadding(context, base: 4)),
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
            icon: Icon(Icons.chevron_right,
                size: _getIconSize(context, base: 22)),
            color: colorScheme.onSurfaceVariant,
            onPressed: currentPage < totalPages
                ? () => _goToPage(currentPage + 1)
                : null,
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

  /// Counts how many currently-loaded products belong to a given category.
  int _countProductsInCategory(String categoryId) {
    return _products.where((p) {
      if (p.category == categoryId) return true;
      if (p.categories != null && p.categories!.contains(categoryId)) {
        return true;
      }
      return false;
    }).length;
  }

  /// Stitch-style price range filter: a RangeSlider with editable min/max
  /// number inputs below it.
  Future<void> _goToPage(int page) async {
    if (page < 1) return;
    _currentPage = page;
    await _fetchProducts(page: page);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedScroll) {
      return _buildEmbeddedLayout();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= 800; // Lower threshold for testing

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }
}

/// Desktop product card matching the Stitch landing grid: hover shadow,
/// image zoom, favorite revealed on hover, and a circular add button.
class _DesktopProductCard extends StatefulWidget {
  const _DesktopProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  State<_DesktopProductCard> createState() => _DesktopProductCardState();
}

class _DesktopProductCardState extends State<_DesktopProductCard> {
  bool _hovered = false;

  String? _getUnit() {
    final raw = widget.product.customAttributes?['unit'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  double? _getDiscount() {
    final raw = widget.product.customAttributes?['discountPercent'];
    if (raw is num && raw > 0) return raw.toDouble();
    return null;
  }

  double _getDiscountedPrice(double discount) {
    return widget.product.basePrice * (1 - discount / 100);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unit = _getUnit();
    final discount = _getDiscount();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.surfaceContainer),
            // Stitch "hover:shadow-lg": a soft lift only while hovering.
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image: flexible so the body below always keeps its natural
              // height. Zooms slightly while hovering (group-hover:scale-105).
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedScale(
                        scale: _hovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerLow,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerLow,
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: colorScheme.outline,
                            ),
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
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
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
                    // Favorite: only revealed on hover, like the Stitch
                    // group-hover:opacity-100 treatment.
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _hovered ? 1.0 : 0.0,
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
                              '${widget.product.name} se agregó a tu lista de deseos',
                              backgroundColor: colorScheme.tertiary,
                              colorText: colorScheme.onTertiary,
                              margin: const EdgeInsets.all(20),
                              borderRadius: 8,
                              duration: const Duration(milliseconds: 1200),
                            ),
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
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        // Stitch group-hover:text-primary.
                        color: _hovered
                            ? colorScheme.primary
                            : colorScheme.onSurface,
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
                                  '\$${widget.product.basePrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    color: colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 1),
                              ],
                              Text(
                                '\$${(discount != null ? _getDiscountedPrice(discount) : widget.product.basePrice).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  color: colorScheme.onSurface,
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
                        // Stitch add button: filled primary when discounted,
                        // primary-container otherwise.
                        Material(
                          color: discount != null
                              ? colorScheme.primary
                              : colorScheme.primaryContainer,
                          shape: CircleBorder(
                            side: discount != null
                                ? BorderSide.none
                                : BorderSide(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.add,
                              color: discount != null
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer,
                            ),
                            onPressed: widget.onAddToCart,
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
      ),
    );
  }
}
