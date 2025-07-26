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
  
  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    try {
      await dotenv.load();
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      final response = await http.get(Uri.parse('$apiUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allProducts = data.map((json) => Product.fromJson(json)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }
  final GlobalKey<ProductListingWidgetState> _productListingKey = GlobalKey();

  void _handleSearch(String query) {
    if (query.isEmpty) {
      _productListingKey.currentState?.updateProducts(allProducts);
      return;
    }

    final filtered = allProducts.where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
      product.id.toLowerCase().contains(query.toLowerCase())
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
            initialProducts: allProducts,
          ),
        ),
      ],
    );
  }
}
