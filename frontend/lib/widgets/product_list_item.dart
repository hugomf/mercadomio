import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: padding),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(padding * 0.5),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  width: imageSize,
                  height: imageSize,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  width: imageSize,
                  height: imageSize,
                  child: Icon(Icons.image, size: imageSize * 0.6, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: padding * 1.5),
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
                  Text(
                    '\$${product.basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
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