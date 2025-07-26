import 'package:flutter/material.dart';

/// Base class for all ControlPanelWidgets
abstract class ControlPanelWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  const ControlPanelWidget({super.key, required this.config});
}

/// Example ProductEditorControlPanelWidget
class ProductEditorControlPanelWidget extends ControlPanelWidget {
  const ProductEditorControlPanelWidget({super.key, required super.config});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement product editor UI
    return const Text('Product Editor');
  }
}

/// Example PriceEditorControlPanelWidget
class PriceEditorControlPanelWidget extends ControlPanelWidget {
  const PriceEditorControlPanelWidget({super.key, required super.config});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement price editor UI
    return const Text('Price Editor');
  }
}
