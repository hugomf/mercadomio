import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/admin_inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _service = AdminInventoryService();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _products.isEmpty;
      _error = null;
    });
    try {
      final page = await _service.getProducts();
      setState(() {
        _products = page.products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _editStock(Product product, ProductVariant variant) async {
    final controller =
        TextEditingController(text: variant.stock.toString());
    final newStock = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set stock - ${variant.variantId}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newStock == null || newStock < 0) {
      if (newStock != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Stock must be a non-negative number'),
            backgroundColor: Colors.red,
          ));
      }
      return;
    }

    try {
      await _service.updateStock(product.id, variant.variantId, newStock);
      if (mounted) {
        setState(() {
          variant.stock = newStock;
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Stock updated'),
            backgroundColor: Colors.green,
          ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Failed to update stock: $e'),
            backgroundColor: Colors.red,
          ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load inventory'),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return const Center(
        child: Text('No products yet'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _products.length,
        itemBuilder: (context, index) => _buildProductCard(_products[index]),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          product.variants.isEmpty
              ? Icons.inventory_2_outlined
              : Icons.inventory,
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${product.variants.length} variant(s) · SKU ${product.sku}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (product.variants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No variants tracked'),
            )
          else
            for (final variant in product.variants)
              _buildVariantRow(product, variant),
        ],
      ),
    );
  }

  Widget _buildVariantRow(Product product, ProductVariant variant) {
    final lowStock = variant.stock <= 5;
    return ListTile(
      leading: CircleAvatar(
        radius: 6,
        backgroundColor: variant.stock <= 0
            ? Colors.red
            : lowStock
                ? Colors.orange
                : Colors.green,
      ),
      title: Text('Variant ${variant.variantId}'),
      subtitle: Text(
        'SKU ${variant.sku.isEmpty ? '-' : variant.sku}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${variant.stock}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: variant.stock <= 0
                  ? Colors.red
                  : lowStock
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit stock',
            onPressed: () => _editStock(product, variant),
          ),
        ],
      ),
    );
  }
}