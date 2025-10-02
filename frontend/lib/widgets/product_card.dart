import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final imageHeight = cardHeight * imageHeightRatio;

    return SizedBox(
      height: cardHeight,
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
                      width: iconSize * 1.2,
                      height: iconSize * 1.2,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: Icon(
                    Icons.image,
                    size: iconSize * 2.4,
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
                    bottomLeft: Radius.circular(padding),
                    bottomRight: Radius.circular(padding),
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
                            Icon(Icons.star, size: starSize, color: Colors.amber),
                            Icon(Icons.star, size: starSize, color: Colors.amber),
                            Icon(Icons.star, size: starSize, color: Colors.amber),
                            Icon(Icons.star, size: starSize, color: Colors.amber),
                            Icon(Icons.star_border, size: starSize, color: Colors.amber),
                            SizedBox(width: padding * 0.5),
                            Text(
                              '4.0',
                              style: TextStyle(
                                fontSize: fontSize * 0.85,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_shopping_cart,
                            size: iconSize,
                            color: Colors.deepPurple,
                          ),
                          onPressed: onAddToCart,
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