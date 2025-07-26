import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'product_listing_widget.dart';
import 'search_widget.dart';

class ProductSearchView extends StatefulWidget {
  const ProductSearchView({super.key});

  @override
  _ProductSearchViewState createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  List<Product> allProducts = [];
  List<Product> searchableProducts = []; // Pre-processed for search
  final GlobalKey<ProductListingWidgetState> _productListingKey = GlobalKey();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load all products for search functionality
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllProducts();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      // Use the same paginated endpoint but with a large limit to get all products for search
      final response = await http.get(Uri.parse('$apiUrl/api/products?page=1&limit=1000')).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> productsData = responseData['data'] ?? [];

          // Parse products with individual error handling
          final List<Product> parsedProducts = [];
          for (final productJson in productsData) {
            try {
              parsedProducts.add(Product.fromJson(productJson));
            } catch (e) {
              // Skip invalid products but continue with others
              continue;
            }
          }

          setState(() {
            allProducts = parsedProducts;
            // Pre-process products for efficient searching
            searchableProducts = parsedProducts.map((product) => Product(
              id: product.id,
              name: product.name.toLowerCase(),
              description: product.description.toLowerCase(),
              type: product.type.toLowerCase(),
              category: product.category.toLowerCase(),
              basePrice: product.basePrice,
              sku: product.sku.toLowerCase(),
              barcode: product.barcode.toLowerCase(),
              imageUrl: product.imageUrl,
              variants: product.variants,
              customAttributes: product.customAttributes,
              identifiers: product.identifiers,
            )).toList();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to parse search data: $e')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Search service error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products for search: $e')),
        );
      }
    }
  }

  void _handleSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search to avoid excessive filtering
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      // Reset to show all products by refreshing the ProductListingWidget
      _productListingKey.currentState?.refreshProducts();
      return;
    }

    final queryLower = query.toLowerCase();
    final filtered = <Product>[];

    // Use pre-processed searchable products for efficient search
    for (int i = 0; i < searchableProducts.length; i++) {
      final searchProduct = searchableProducts[i];
      if (searchProduct.name.contains(queryLower) ||
          searchProduct.description.contains(queryLower) ||
          searchProduct.category.contains(queryLower) ||
          searchProduct.sku.contains(queryLower)) {
        filtered.add(allProducts[i]); // Add original product
      }
    }

    _productListingKey.currentState?.updateProducts(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchWidget(onSearch: _handleSearch),
        Expanded(
          child: ProductListingWidget(
            key: _productListingKey,
            // Don't pass initialProducts, let ProductListingWidget handle its own loading
          ),
        ),
      ],
    );
  }
}
