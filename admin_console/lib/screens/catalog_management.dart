import 'package:flutter/material.dart';
import 'package:admin_console/models/product.dart';
import 'package:admin_console/services/admin_inventory_service.dart';
import 'package:admin_console/widgets/navigation_drawer.dart' as custom;

class CatalogManagementScreen extends StatefulWidget {
  const CatalogManagementScreen({super.key});

  @override
  State<CatalogManagementScreen> createState() => _CatalogManagementScreenState();
}

class _CatalogManagementScreenState extends State<CatalogManagementScreen> {
  final AdminInventoryService _service = AdminInventoryService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _products.isEmpty;
      _error = null;
    });
    try {
      final page = await _service.getProducts(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _products = page.products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      final name = p.name.toLowerCase();
      final sku = p.sku.toLowerCase();
      return name.contains(q) || sku.contains(q);
    }).toList();
  }

  Future<void> _editStock(Product product, ProductVariant variant) async {
    final controller = TextEditingController(text: '${variant.stock}');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit stock — ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variant: ${variant.variantId}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result < 0) {
      if (result != null && result < 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock must be a non-negative number'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      await _service.updateStock(product.id, variant.variantId, result);
      if (!mounted) return;
      setState(() {
        variant.stock = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated for ${product.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update stock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit Product', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: product.imageUrl.isEmpty
                            ? const Icon(Icons.image, size: 32, color: Colors.grey)
                            : Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 32, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('SKU: ${product.sku}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('\$${product.basePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepPurple)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: product.variants.isEmpty
                      ? const Center(child: Text('No variants tracked'))
                      : ListView(
                          children: product.variants
                              .map((variant) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      variant.stock <= 0
                                          ? Icons.cancel
                                          : variant.stock <= 5
                                              ? Icons.warning_amber
                                              : Icons.check_circle,
                                      color: variant.stock <= 0
                                          ? Colors.red
                                          : variant.stock <= 5
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                    title: Text(
                                      'Variant ${variant.variantId}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      'SKU: ${variant.sku}',
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
                                                : variant.stock <= 5
                                                    ? Colors.orange
                                                    : Colors.green,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _editStock(product, variant);
                                    },
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Could not load catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('$_error',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('No products found', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Search products…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final products = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
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
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('Variants')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('')),
          ],
          rows: products.map((product) {
            final totalStock = product.variants.fold<int>(0, (sum, v) => sum + v.stock);
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: product.imageUrl.isEmpty
                              ? const Icon(Icons.image, color: Colors.grey)
                              : Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('${product.variants.length} variant(s) · $totalStock in stock',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(product.sku, style: const TextStyle(fontSize: 14))),
                DataCell(Text('${product.variants.length}',
                    style: const TextStyle(fontSize: 14))),
                DataCell(Text('\$${product.basePrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))),
                DataCell(
                  IconButton(
                    tooltip: 'Edit product',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditDialog(product),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final products = _filtered;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text('No products found', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...products.map(
              (product) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withAlpha(25),
                    child: Icon(
                      product.variants.fold<int>(0, (sum, v) => sum + v.stock) <= 0
                          ? Icons.inventory_2_outlined
                          : Icons.inventory_2,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${product.variants.length} variant(s) · SKU ${product.sku}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditDialog(product),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog Management'),
      ),
      drawer: const custom.NavigationDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _products.isEmpty
                    ? _buildError(context)
                    : isDesktop
                        ? (_filtered.isEmpty ? _buildEmpty() : _buildDesktopTable(context))
                        : _buildMobileList(),
          ),
        ],
      ),
    );
  }
}