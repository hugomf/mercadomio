import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

/// Product card matching the Stitch mock: discount badge at top-left,
/// favorite icon revealed on hover, and a circular add button.
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final double cardHeight;
  final double imageHeightRatio;
  final double padding;
  final double fontSize;
  final double iconSize;
  final double starSize;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.cardHeight,
    required this.imageHeightRatio,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.starSize,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

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
    final imageHeight = widget.cardHeight * widget.imageHeightRatio;
    final discount = _getDiscount();
    final hasDiscount = discount != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Card(
        elevation: _hovered ? 4 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            // Image with discount badge + favorite icon
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceContainerLow,
                        child: Center(
                          child: SizedBox(
                            width: widget.iconSize * 1.2,
                            height: widget.iconSize * 1.2,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerLow,
                        child: Icon(
                          Icons.image,
                          size: widget.iconSize * 2.4,
                          color: colorScheme.outline,
                        ),
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: imageHeight,
                    ),
                  ),
                  // Discount badge (top-left, matching Stitch mock)
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
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
                  // Favorite icon (revealed on hover, matching Stitch mock)
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${widget.product.name} se agregó a tu lista de deseos'),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(widget.padding),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(widget.padding),
                    bottomRight: Radius.circular(widget.padding),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: widget.fontSize,
                        color: _hovered
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Price section: original (strikethrough) + discounted
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDiscount)
                          Text(
                            '\$${widget.product.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: widget.fontSize * 0.85,
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.outline,
                            ),
                          ),
                        Text(
                          '\$${(hasDiscount
                              ? _getDiscountedPrice(discount)
                              : widget.product.basePrice).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: widget.fontSize * 1.15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: widget.starSize, color: Colors.amber),
                            Icon(Icons.star,
                                size: widget.starSize, color: Colors.amber),
                            Icon(Icons.star,
                                size: widget.starSize, color: Colors.amber),
                            Icon(Icons.star,
                                size: widget.starSize, color: Colors.amber),
                            Icon(Icons.star_border,
                                size: widget.starSize, color: Colors.amber),
                            SizedBox(width: widget.padding * 0.5),
                            Flexible(
                              child: Text(
                                widget.product.averageRating > 0
                                    ? widget.product.averageRating
                                        .toStringAsFixed(1)
                                    : '4.0',
                                style: TextStyle(
                                  fontSize: widget.fontSize * 0.85,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (widget.product.reviewCount > 0)
                              Flexible(
                                child: Text(
                                  '(${widget.product.reviewCount})',
                                  style: TextStyle(
                                    fontSize: widget.fontSize * 0.8,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_shopping_cart,
                            size: widget.iconSize,
                            color: colorScheme.primary,
                          ),
                          onPressed: widget.onAddToCart,
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
    );
  }
}