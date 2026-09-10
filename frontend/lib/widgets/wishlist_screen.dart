import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/cart_controller.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final AuthService authService = Get.find<AuthService>();
  final ProductService productService = Get.find<ProductService>();
  final CartController cartController = Get.find<CartController>();

  final RxList<Product> _wishlistProducts = <Product>[].obs;
  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final wishlistIds = await authService.getUserWishlist();
      final products = <Product>[];

      for (final id in wishlistIds) {
        try {
          final product = await productService.getProductDetails(id);
          products.add(product);
        } catch (_) {
          // Skip products that can't be loaded
        }
      }

      _wishlistProducts.value = products;
    } catch (e) {
      _errorMessage.value = 'Error al cargar la lista de deseos: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      await authService.removeFromWishlist(productId);
      _wishlistProducts.removeWhere((p) => p.id == productId);
      Get.snackbar(
        'Eliminado',
        'Producto eliminado de tu lista de deseos',
        backgroundColor: Get.theme.colorScheme.tertiary,
        colorText: Get.theme.colorScheme.onTertiary,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar de la lista de deseos',
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
      appBar: AppBar(
        title: const Text('Lista de Deseos'),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Get.theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.value,
                  style: TextStyle(color: Get.theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadWishlist,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (_wishlistProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Get.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu lista de deseos está vacía',
                  style: TextStyle(
                    fontSize: 18,
                    color: Get.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega productos que te gusten para verlos aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: Get.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed('/'),
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Ir a la tienda'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadWishlist,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = _wishlistProducts[index];
              return _buildWishlistCard(product);
            },
          ),
        );
      }),
    );
  }

  Widget _buildWishlistCard(Product product) {
    final colorScheme = Get.theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(productId: product.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.shopping_bag,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.averageRating > 0) ...[
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < product.averageRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewCount})',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '\$${product.basePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () => _removeFromWishlist(product.id),
                    icon: const Icon(Icons.favorite),
                    color: colorScheme.error,
                    tooltip: 'Eliminar de favoritos',
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await cartController.addToCart(
                          productId: product.id,
                          variantId: product.variants.isNotEmpty ? product.variants.first.variantId : '',
                          quantity: 1,
                        );
                        Get.snackbar(
                          'Agregado al carrito',
                          product.name,
                          backgroundColor: colorScheme.primary,
                          colorText: colorScheme.onPrimary,
                          margin: const EdgeInsets.all(20),
                          borderRadius: 8,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'No se pudo agregar al carrito',
                          backgroundColor: colorScheme.error,
                          colorText: colorScheme.onError,
                          margin: const EdgeInsets.all(20),
                          borderRadius: 8,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Agregar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
