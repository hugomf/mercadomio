import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

/// List-item style product row matching the Stitch mock aesthetic:
/// discount badge, favorite icon, and discounted price with strikethrough.
class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final double imageSize;
  final double padding;
  final double fontSize;
  final double iconSize;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.imageSize,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });

  double? _getDiscount() {
    final raw = product.customAttributes?['discountPercent'];
    if (raw is num && raw > 0) return raw.toDouble();
    return null;
  }

  double _getDiscountedPrice(double discount) {
    return product.basePrice * (1 - discount / 100);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final discount = _getDiscount();
    final hasDiscount = discount != null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: padding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image with optional discount badge
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(padding * 0.5),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerLow,
                        width: imageSize,
                        height: imageSize,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerLow,
                        width: imageSize,
                        height: imageSize,
                        child: Icon(Icons.image,
                            size: imageSize * 0.6,
                            color: colorScheme.outline),
                      ),
                    ),
                  ),
                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${discount.round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: padding * 1.5),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: padding * 0.5),
                  // Price: original (strikethrough) + discounted
                  if (hasDiscount)
                    Text(
                      '\$${product.basePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: fontSize * 0.85,
                        decoration: TextDecoration.lineThrough,
                        color: colorScheme.outline,
                      ),
                    ),
                  Text(
                    '\$${(hasDiscount
                        ? _getDiscountedPrice(discount)
                        : product.basePrice).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              )),
            // Favorite icon
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${product.name} se agregó a tu lista de deseos'),
                    duration: const Duration(milliseconds: 1200),
                    backgroundColor: colorScheme.tertiary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Add to cart
            IconButton(
              icon: Icon(Icons.add_shopping_cart, size: iconSize),
              onPressed: onAddToCart,
            ),
          ],
        ),
      ),
    );
  }
}