import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/admin_inventory_service.dart';
import '../widgets/navigation_drawer.dart' as custom;

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
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        drawer: const custom.NavigationDrawer(),
        body: Center(
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
        ),
      );
    }
    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        drawer: const custom.NavigationDrawer(),
        body: const Center(
          child: Text('No products yet'),
        ),
      );
    }
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      drawer: const custom.NavigationDrawer(),
      body: isDesktop
          ? RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _buildDesktopStockTable(context),
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _products.length,
                itemBuilder: (context, index) => _buildProductCard(_products[index]),
              ),
            ),
    );
  }

  Widget _buildDesktopStockTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowHeight: 48,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dataRowMinHeight: 60,
        dataRowMaxHeight: 72,
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Variant')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final product in _products)
            ...product.variants.isEmpty
                ? [
                    DataRow(
                      cells: [
                        DataCell(Text(product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                        const DataCell(Text('—')),
                        DataCell(Text(product.sku)),
                        const DataCell(Text('0')),
                        const DataCell(SizedBox()),
                      ],
                    ),
                  ]
                : [
                    for (final variant in product.variants)
                      DataRow(
                        cells: [
                          DataCell(Text(product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('Variant ${variant.variantId}',
                              style: const TextStyle(fontSize: 14))),
                          DataCell(Text(variant.sku.isEmpty ? '—' : variant.sku,
                              style: const TextStyle(fontSize: 14))),
                          DataCell(
                            _stockBubble(variant.stock),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: 'Edit stock',
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editStock(product, variant),
                            ),
                          ),
                        ],
                      ),
                  ],
        ],
      ),
    );
  }

  Widget _stockBubble(int stock) {
    final lowStock = stock <= 5;
    final color = stock <= 0
        ? Colors.red
        : lowStock
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$stock',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
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