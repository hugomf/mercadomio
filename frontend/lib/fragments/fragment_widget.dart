import 'package:flutter/material.dart';

/// Base class for all FragmentWidgets
abstract class FragmentWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  const FragmentWidget({super.key, required this.config});
}

/// Example ProductListingFragmentWidget
class ProductListingFragmentWidget extends FragmentWidget {
  const ProductListingFragmentWidget({super.key, required super.config});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement product listing UI
    return const Text('Product Listing');
  }
}

/// Example PriceDisplayFragmentWidget
class PriceDisplayFragmentWidget extends FragmentWidget {
  const PriceDisplayFragmentWidget({super.key, required super.config});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement price display UI
    return const Text('Price Display');
  }
}
