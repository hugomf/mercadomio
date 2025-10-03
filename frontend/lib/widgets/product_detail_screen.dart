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
      _errorMessage.value = 'Failed to load product details: ${e.toString()}';
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
      'Added to Cart',
      '${product!.name} was added to your cart',
      duration: const Duration(milliseconds: 1500),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: 8,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  Future<void> _toggleWishlist() async {
    if (product == null || !authService.isAuthenticated) {
      Get.snackbar(
        'Authentication Required',
        'Please login to add items to your wishlist',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // For now, just add to wishlist since we don't have isInWishlist method
      await authService.addToWishlist(product!.id);
      Get.snackbar(
        'Added to Wishlist',
        '${product!.name} was added to your wishlist',
        backgroundColor: Colors.pink,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add to wishlist: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (product == null) {
          return const Center(child: Text('Product not found'));
        }

        return CustomScrollView(
          slivers: [
            // App Bar with Image Gallery
            _buildAppBar(),

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

                    const SizedBox(height: 32),

                    // Add to Cart Section
                    _buildAddToCartSection(),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Obx(() {
          if (product == null || product!.images.isEmpty) {
            return CachedNetworkImage(
              imageUrl: product?.imageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            );
          }

          final currentImage = product!.images[_selectedImageIndex.value];
          return CachedNetworkImage(
            imageUrl: currentImage.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          );
        }),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implement share functionality
          },
        ),
        Obx(() => IconButton(
          icon: Icon(
            authService.isAuthenticated
                ? Icons.favorite
                : Icons.favorite_border,
            color: authService.isAuthenticated ? Colors.red : null,
          ),
          onPressed: _toggleWishlist,
        )),
      ],
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
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
                      : Colors.grey,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${product!.averageRating.toStringAsFixed(1)} (${product!.reviewCount} reviews)',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // SKU
        Text(
          'SKU: ${product!.sku}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
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
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
                          ? Colors.deepPurple
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: image.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
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
        const Text(
          'Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.grey[200],
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
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full reviews page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Rating Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
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
                                  : Colors.grey,
                            );
                          }),
                        ),
                        Text(
                          '${product!.reviewCount} reviews',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
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
          const Text(
            'No reviews yet. Be the first to review this product!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
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
            backgroundColor: Colors.grey[300],
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
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
                    color: index < review.rating ? Colors.amber : Colors.grey,
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
        const Text(
          'Related Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
                  color: Colors.grey[200],
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
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

  Widget _buildAddToCartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Quantity Selector
          Row(
            children: [
              const Text(
                'Quantity:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_quantity.value > 1) {
                    _quantity.value--;
                  }
                },
              ),
              Obx(() => Text(
                '${_quantity.value}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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

          const SizedBox(height: 16),

          // Add to Cart Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
