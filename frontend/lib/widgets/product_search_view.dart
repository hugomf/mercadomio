import 'package:flutter/material.dart';
import 'dart:async';
import 'product_listing_widget.dart';
import 'search_widget.dart';

class ProductSearchView extends StatefulWidget {
  const ProductSearchView({super.key});

  @override
  _ProductSearchViewState createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  final GlobalKey<ProductListingWidgetState> _productListingKey = GlobalKey();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }



  void _handleSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search to avoid excessive API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    // Use the new server-side search with pagination
    _productListingKey.currentState?.searchProducts(query);
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
