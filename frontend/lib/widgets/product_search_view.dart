import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_listing_widget.dart';
import 'search_widget.dart';

class ProductSearchView extends StatefulWidget {
  const ProductSearchView({super.key});

  @override
  _ProductSearchViewState createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  List<Product> allProducts = [];
  final GlobalKey<ProductListingWidgetState> _productListingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load all products for search functionality
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllProducts();
    });
  }

  Future<void> _loadAllProducts() async {
    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      // Use the same paginated endpoint but with a large limit to get all products for search
      final response = await http.get(Uri.parse('$apiUrl/api/products?page=1&limit=1000'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productsData = responseData['data'] ?? [];
        setState(() {
          allProducts = productsData.map((json) => Product.fromJson(json)).toList();
        });
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
    if (query.isEmpty) {
      // Reset to show all products by refreshing the ProductListingWidget
      _productListingKey.currentState?.refreshProducts();
      return;
    }

    final filtered = allProducts.where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
      product.description.toLowerCase().contains(query.toLowerCase()) ||
      product.category.toLowerCase().contains(query.toLowerCase()) ||
      product.sku.toLowerCase().contains(query.toLowerCase())
    ).toList();

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
