import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/category_service.dart';
import '../models/product.dart';

class ProductListingWidget extends StatefulWidget {
  const ProductListingWidget({super.key});

  @override
  State<ProductListingWidget> createState() => ProductListingWidgetState();
}

class ProductListingWidgetState extends State<ProductListingWidget> {
  final RxList<Product> _products = <Product>[].obs;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    // TODO: Implement actual product fetching
    await Future.delayed(const Duration(seconds: 1));
    _products.value = List.generate(10, (index) => Product(
      id: index.toString(),
      name: 'Product ${index + 1}',
      price: 19.99,
      imageUrl: 'https://picsum.photos/200?random=$index',
      categoryIds: [],
    ));
  }

  void searchProducts(String query) {
    // TODO: Implement actual search functionality
    // For now just filter the existing products
    _products.value = _products.where((p) =>
      p.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final CategoryService categoryService = Get.find();
    
    return Column(
      children: [
        Obx(() {
          if (categoryService.selectedCategoryId.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  FilterChip(
                    label: const Text('Clear filters'),
                    onSelected: (_) {
                      categoryService.selectedCategoryId.value = '';
                    },
                  ),
                  ...categoryService.categories
                      .where((cat) => cat.id == categoryService.selectedCategoryId.value)
                      .map((cat) => FilterChip(
                            label: Text(cat.name),
                            onSelected: (_) {},
                          ))
                      .toList(),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Expanded(
          child: Obx(() {
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.75,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8.0)),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            placeholder: (context, url) => 
                              const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => 
                              const Icon(Icons.error),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('\$${product.price.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}