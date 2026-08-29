import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../services/cart_controller.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService productService = Get.find<ProductService>();
  final AuthService authService = Get.find<AuthService>();
  final CartController cartController = Get.find<CartController>();

  final Rx<Product?> _product = Rx<Product?>(null);
  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;
  final RxInt _selectedImageIndex = 0.obs;
  final RxString _selectedVariantId = ''.obs;
  final RxInt _quantity = 1.obs;

  Product? get product => _product.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final productDetails = await productService.getProductDetails(widget.productId);
      _product.value = productDetails;

      // Set default variant if available
      if (productDetails.variants.isNotEmpty) {
        _selectedVariantId.value = productDetails.variants.first.variantId;
      }
    } catch (e) {
      _errorMessage.value = 'Error al cargar el producto: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  double get _currentPrice {
    if (product == null) return 0.0;

    // If a variant is selected, use its price
    if (_selectedVariantId.value.isNotEmpty) {
      final selectedVariant = product!.variants.firstWhere(
        (v) => v.variantId == _selectedVariantId.value,
        orElse: () => product!.variants.first,
      );
      return selectedVariant.price > 0 ? selectedVariant.price : product!.basePrice;
    }

    return product!.basePrice;
  }

  void _addToCart() {
    if (product == null) return;

    cartController.addToCart(
      productId: product!.id,
      variantId: _selectedVariantId.value.isNotEmpty ? _selectedVariantId.value : null,
      quantity: _quantity.value,
    );

    Get.snackbar(
      'Agregado al carrito',
      '${product!.name} se agregó a tu carrito',
      duration: const Duration(milliseconds: 1500),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: 8,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  Future<void> _toggleWishlist() async {
    if (product == null || !authService.isAuthenticated) {
      Get.snackbar(
        'Inicia sesión',
        'Inicia sesión para agregar artículos a tu lista de deseos',
        backgroundColor: Get.theme.colorScheme.tertiary,
        colorText: Get.theme.colorScheme.onTertiary,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
      return;
    }

    try {
      // For now, just add to wishlist since we don't have isInWishlist method
      await authService.addToWishlist(product!.id);
      Get.snackbar(
        'Agregado a favoritos',
        '${product!.name} se agregó a tu lista de deseos',
        backgroundColor: Get.theme.colorScheme.tertiary,
        colorText: Get.theme.colorScheme.onTertiary,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo agregar a favoritos: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProductDetails,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (product == null) {
          return Center(
            child: Text(
              'Producto no encontrado',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        if (MediaQuery.of(context).size.width >= 800) {
          return _buildDesktopLayout();
        }

        // MOBILE layout: matches the Stitch mock with a sticky footer
        // containing the "Agregar al carrito" button.
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar with Image Gallery + discount badge
              _buildMobileAppBarWithBadge(),

              // Product Information
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title and Price
                      _buildProductHeader(),

                      const SizedBox(height: 16),

                      // Chips: "Pieza aprox. 120g" / "Origen: Local"
                      _buildMobileInfoChips(),

                      const SizedBox(height: 16),

                      // Image Gallery
                      _buildImageGallery(),

                      const SizedBox(height: 24),

                      // Variants
                      if (product!.variants.isNotEmpty) ...[
                        _buildVariantsSection(),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      _buildDescriptionSection(),

                      const SizedBox(height: 24),

                      // Reviews Section
                      _buildReviewsSection(),

                      const SizedBox(height: 24),

                      // Related Products
                      _buildRelatedProductsSection(),

                      // Keep extra spacer so the sticky footer doesn't
                      // overlap the last content section.
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildMobileStickyFooter(),
        );
      }),
    );
  }

  Widget _buildDesktopLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    final discount = _desktopDiscount;
    return Column(
      children: [
        // Top bar with breadcrumb, search, nav, cart — matches Stitch TopNavBar
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Logo + nav links (hidden on mobile but present in desktop)
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Text(
                      'Mercadomio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildDesktopNavLink('Frutas y Verduras', true, colorScheme),
                    _buildDesktopNavLink('Panadería', false, colorScheme),
                    _buildDesktopNavLink('Despensa', false, colorScheme),
                    _buildDesktopNavLink('Lácteos', false, colorScheme),
                  ],
                ),
              ),
              // Search field (centered)
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(Icons.search,
                            size: 20, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar productos...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions: location, account, cart
              Row(
                children: [
                  _buildDesktopIconButton(Icons.location_on_outlined,
                      'Ubicación', colorScheme),
                  _buildDesktopIconButton(Icons.person_outline, 'Cuenta',
                      colorScheme),
                  _buildDesktopIconButton(
                      Icons.shopping_cart_outlined, 'Carrito', colorScheme,
                      isPrimary: true),
                ],
              ),
            ],
          ),
        ),
        // Divider
        Container(
          height: 1,
          color: colorScheme.outlineVariant,
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    _buildDesktopBreadcrumb(colorScheme),
                    const SizedBox(height: 24),
                    // Product Grid: 2 columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Image Gallery (5/12)
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  _buildDesktopMainImage(),
                                  if (discount != null)
                                    Positioned(
                                      top: 16,
                                      left: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '-${discount.round()}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (product!.images.length > 1)
                                _buildDesktopThumbnails(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right: Info Panel (7/12)
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Organic badge
                              if (_organicTag != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _organicTag!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: colorScheme.onSecondaryContainer,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Category tag
                              if (product!.category != null) ...[
                                Text(
                                  product!.category!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Product name
                              Text(
                                product!.name,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Rating
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        Icons.star,
                                        size: 20,
                                        color: index <
                                                product!.averageRating.floor()
                                            ? Colors.amber
                                            : colorScheme.outlineVariant,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${product!.averageRating.toStringAsFixed(1)} '
                                    '(${product!.reviewCount} reseñas)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Price row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (discount != null) ...[
                                    Text(
                                      '\$${_desktopOriginalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        decoration:
                                            TextDecoration.lineThrough,
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Text(
                                    '\$${_currentPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  if (_unitLabel != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '/ $_unitLabel',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Quick Info Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: colorScheme.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildQuickInfoRow(Icons.eco, 'Origen',
                                        'Producción Local', colorScheme),
                                    const SizedBox(height: 12),
                                    _buildQuickInfoRow(Icons.local_shipping,
                                        'Entrega hoy',
                                        'Pide antes de las 2 PM', colorScheme),
                                    const SizedBox(height: 12),
                                    _buildQuickInfoRow(Icons.verified,
                                        'Calidad Premium',
                                        'Selección a mano', colorScheme),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (product!.variants.isNotEmpty) ...[
                                _buildVariantsSection(),
                                const SizedBox(height: 20),
                              ],
                              // Purchase box with rounded-full stepper and button
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLowest,
                                  border: Border.all(
                                      color: colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _buildDesktopQuantityStepper(),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _addToCart,
                                        icon:
                                            const Icon(Icons.shopping_cart),
                                        label: const Text(
                                          'Agregar al carrito',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildDesktopAccordions(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    _buildReviewsSection(),
                    const SizedBox(height: 48),
                    _buildRelatedProductsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Discount percent computed by the backend pricing engine (difference
  /// between base price and resolved price). Only present when a real
  /// discount applies. Null otherwise.
  double? get _desktopDiscount {
    final attrs = product?.customAttributes;
    final raw = attrs?['discountPercent'];
    if (raw is num && raw > 0) return raw.toDouble();
    return null;
  }

  /// Original (base) price before the engine discount, derived from the
  /// current price and discount percent. Falls back to the current price
  /// when no discount applies.
  double get _desktopOriginalPrice {
    final discount = _desktopDiscount;
    if (discount == null) return _currentPrice;
    return _currentPrice / (1 - discount / 100);
  }

  /// Organic badge text when the product is marked as organic, either via a
  /// boolean or string `organic` custom attribute, or an 'org'-matching tag.
  String? get _organicTag {
    final attrs = product?.customAttributes;
    final raw = attrs?['organic'];
    if (raw is bool && raw) return 'Orgánico';
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    for (final tag in product?.tags ?? const []) {
      if (tag.toLowerCase().contains('org')) return tag;
    }
    return null;
  }

  /// Unit label provided by the backend pricing engine (e.g. 'kg', 'L').
  String? get _unitLabel {
    final raw = product?.customAttributes?['unit'];
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  /// Static breadcrumb for the desktop top bar: Inicio > category > name.
  /// 'Inicio' pops back to the previous screen; the current product name is
  /// the last (bold) segment.
  Widget _buildDesktopBreadcrumb(ColorScheme colorScheme) {
    final category = product?.category;
    final name = product?.name ?? '';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Inicio',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (category != null) ...[
            Icon(Icons.chevron_right,
                size: 16, color: colorScheme.outline),
            Text(
              category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          Icon(Icons.chevron_right, size: 16, color: colorScheme.outline),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for top nav links
  Widget _buildDesktopNavLink(String label, bool isActive, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // Helper for top bar icon buttons
  Widget _buildDesktopIconButton(IconData icon, String tooltip,
      ColorScheme colorScheme, {bool isPrimary = false}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isPrimary ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: IconButton(
          icon: Icon(icon, size: 22),
          color: isPrimary ? colorScheme.onPrimaryContainer : colorScheme.primary,
          onPressed: () {
            if (tooltip == 'Carrito') Get.toNamed('/cart');
            if (tooltip == 'Cuenta') Get.toNamed('/profile');
            if (tooltip == 'Ubicación') Get.snackbar('Ubicación', 'Seleccionar ubicación');
          },
        ),
      ),
    );
  }

  Widget _buildQuickInfoRow(IconData icon, String label, String value,
      ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: value),
            ]),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopQuantityStepper() {
    final colorScheme = Get.theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              if (_quantity.value > 1) {
                _quantity.value--;
              }
            },
          ),
          Obx(() => Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '${_quantity.value}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          )),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _quantity.value++;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAccordions() {
    return Column(
      children: [
        _buildAccordionItem(
          title: 'Descripción',
          initiallyExpanded: true,
          child: Text(
            product!.description,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        _buildAccordionItem(
          title: 'Información Nutrimental',
          child: Text(
            'Información nutrimental pendiente de agregar para este producto.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildAccordionItem(
          title: 'Envío',
          child: Text(
            'Disponible para entrega el día de hoy si tu pedido se realiza antes de las 2 PM.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionItem({
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }

  Widget _buildDesktopMainImage() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Obx(() {
            if (product!.images.isEmpty) {
              return CachedNetworkImage(
                imageUrl: product!.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Icon(Icons.image, size: 100, color: Theme.of(context).colorScheme.outline),
                ),
              );
            }
            final currentImage = product!.images[_selectedImageIndex.value];
            return CachedNetworkImage(
              imageUrl: currentImage.url,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Icon(Icons.image, size: 100, color: Theme.of(context).colorScheme.outline),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDesktopThumbnails() {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: product!.images.length,
        itemBuilder: (context, index) {
          final image = product!.images[index];
          return Obx(() => GestureDetector(
            onTap: () => _selectedImageIndex.value = index,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedImageIndex.value == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Icon(Icons.image, color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ),
          ));
        },
      ),
    );
  }


  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        Text(
          product!.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Price
        Text(
          '\$${_currentPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        const SizedBox(height: 8),

        // Rating and Reviews
        Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  size: 20,
                  color: index < product!.averageRating.floor()
                      ? Colors.amber
                      : Theme.of(context).colorScheme.outlineVariant,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${product!.averageRating.toStringAsFixed(1)} (${product!.reviewCount} reseñas)',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // SKU
        Text(
          'SKU: ${product!.sku}',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    if (product == null || product!.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imágenes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: product!.images.length,
            itemBuilder: (context, index) {
              final image = product!.images[index];
              return Obx(() => GestureDetector(
                onTap: () => _selectedImageIndex.value = index,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedImageIndex.value == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: image.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.image, color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product!.variants.map((variant) {
            return Obx(() => ChoiceChip(
              label: Text(variant.name),
              selected: _selectedVariantId.value == variant.variantId,
              onSelected: (selected) {
                if (selected) {
                  _selectedVariantId.value = variant.variantId;
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product!.description,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reseñas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full reviews page
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Rating Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          product!.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 20,
                              color: index < product!.averageRating.floor()
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.outlineVariant,
                            );
                          }),
                        ),
                        Text(
                          '${product!.reviewCount} reseñas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar(5, 0.8),
                        _buildRatingBar(4, 0.6),
                        _buildRatingBar(3, 0.3),
                        _buildRatingBar(2, 0.1),
                        _buildRatingBar(1, 0.05),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recent Reviews
        if (product!.reviews.isNotEmpty) ...[
          ...product!.reviews.take(3).map((review) => _buildReviewItem(review)),
        ] else
          Text(
            'Aún no hay reseñas. ¡Sé el primero en opinar sobre este producto!',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        Text('$stars'),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(percentage * 100).toInt()}%'),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: index < review.rating ? Colors.amber : Theme.of(context).colorScheme.outlineVariant,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                review.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment),
        ],
      ),
    );
  }

  Widget _buildRelatedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos Relacionados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: product!.relatedProducts.length,
            itemBuilder: (context, index) {
              return _buildRelatedProductCard(product!.relatedProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(String productId) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: 'https://via.placeholder.com/150', // TODO: Get actual image
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related Product', // TODO: Get actual product name
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$0.00', // TODO: Get actual price
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Mobile App Bar with discount badge overlaid on the hero image.
  Widget _buildMobileAppBarWithBadge() {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
        color: Colors.white,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => Get.snackbar(
            'Compartir',
            'Compartiendo ${product!.name}',
            backgroundColor: colorScheme.tertiary,
            colorText: colorScheme.onTertiary,
            margin: const EdgeInsets.all(20),
            borderRadius: 8,
          ),
          color: Colors.white,
        ),
        Obx(() => IconButton(
            icon: Icon(
              authService.isAuthenticated
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: authService.isAuthenticated
                  ? colorScheme.tertiary
                  : Colors.white,
            ),
            onPressed: _toggleWishlist,
          )),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Obx(() {
          if (product == null || product!.images.isEmpty) {
            return CachedNetworkImage(
              imageUrl: product?.imageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: colorScheme.surfaceContainerHigh,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: colorScheme.surfaceContainerHigh,
                child: const Icon(Icons.image, size: 80),
              ),
            );
          }
          final currentImage = product!.images[_selectedImageIndex.value];
          return CachedNetworkImage(
            imageUrl: currentImage.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: colorScheme.surfaceContainerHigh,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: colorScheme.surfaceContainerHigh,
              child: const Icon(Icons.image, size: 80),
            ),
          );
        }),
      ),
    );
  }

  /// Info chips shown below the product title on mobile ("Pieza aprox." / "Origen").
  Widget _buildMobileInfoChips() {
    final colorScheme = Theme.of(context).colorScheme;
    final unitLabel = _unitLabel;
    final category = product?.category;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (unitLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pieza aprox. $unitLabel',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
                fontFamily: 'Inter',
              ),
            ),
          ),
        if (category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Origen: Local',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onTertiaryContainer,
                fontFamily: 'Inter',
              ),
            ),
          ),
      ],
    );
  }

  /// Sticky footer on mobile with the quantity selector + "Agregar al Carrito"
  /// button (matches the Stitch mobile mock's persistent checkout bar).
  Widget _buildMobileStickyFooter() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildDesktopQuantityStepper(),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.shopping_cart),
                label: const Text(
                  'Agregar al Carrito',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
