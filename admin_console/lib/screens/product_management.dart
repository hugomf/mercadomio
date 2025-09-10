import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../widgets/navigation_drawer.dart' as custom;
import '../services/product_provider.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final List<Category> _categories = [
    Category(
      id: '1',
      name: 'Electronics',
      description: 'Electronic devices',
      path: '/1/',
      depth: 1,
    ),
    Category(
      id: '2',
      name: 'Clothing',
      description: 'Apparel and accessories',
      path: '/2/',
      depth: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load products from backend when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
            tooltip: 'Add New Product',
          ),
        ],
      ),
      drawer: const custom.NavigationDrawer(),
      body: _buildProductList(),
    );
  }

  Widget _buildProductList() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${productProvider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => productProvider.loadProducts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (productProvider.products.isEmpty) {
          return const Center(
            child: Text('No products found. Add your first product!'),
          );
        }

        return ListView.builder(
          itemCount: productProvider.products.length,
          itemBuilder: (context, index) {
            final product = productProvider.products[index];
            return _buildProductCard(product, productProvider);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, ProductProvider productProvider) {
    final categoryNames = product.categoryIds.map((categoryId) {
      final category = _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => Category(
          id: categoryId,
          name: 'Unknown Category',
          description: '',
          path: '/$categoryId/',
          depth: 1,
        ),
      );
      return category.name;
    }).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: product.imageUrl.isNotEmpty
            ? Image.network(
                product.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.shopping_bag, size: 40);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
              )
            : const Icon(Icons.shopping_bag, size: 40),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 4),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Stock: ${product.stockQuantity}'),
            Text('Categories: $categoryNames'),
            Text(
              product.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: product.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProductDialog(product, productProvider),
              tooltip: 'Edit Product',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteProduct(product.id, productProvider),
              tooltip: 'Delete Product',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final imageUrlController = TextEditingController();
    final selectedCategories = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Product'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Price is required';
                        final price = double.tryParse(value!);
                        if (price == null || price <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Stock is required';
                        final stock = int.tryParse(value!);
                        if (stock == null || stock < 0) {
                          return 'Enter valid stock quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Categories:'),
                    ..._categories.map((category) {
                      return CheckboxListTile(
                        title: Text(category.name),
                        value: selectedCategories.contains(category.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedCategories.add(category.id);
                            } else {
                              selectedCategories.remove(category.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final newProduct = Product(
                      id: '', // Backend will generate ID
                      name: nameController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      stockQuantity: int.parse(stockController.text),
                      categoryIds: selectedCategories.toList(),
                      imageUrl: imageUrlController.text,
                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    productProvider.addProduct(newProduct);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(Product product, ProductProvider productProvider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stockQuantity.toString());
    final imageUrlController = TextEditingController(text: product.imageUrl);
    final selectedCategories = Set<String>.from(product.categoryIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Product'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Price is required';
                        final price = double.tryParse(value!);
                        if (price == null || price <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Stock is required';
                        final stock = int.tryParse(value!);
                        if (stock == null || stock < 0) {
                          return 'Enter valid stock quantity';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Categories:'),
                    ..._categories.map((category) {
                      return CheckboxListTile(
                        title: Text(category.name),
                        value: selectedCategories.contains(category.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedCategories.add(category.id);
                            } else {
                              selectedCategories.remove(category.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final updatedProduct = Product(
                      id: product.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      stockQuantity: int.parse(stockController.text),
                      categoryIds: selectedCategories.toList(),
                      imageUrl: product.imageUrl,
                      isActive: product.isActive,
                      createdAt: product.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    productProvider.updateProduct(product.id, updatedProduct);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteProduct(String id, ProductProvider productProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              productProvider.deleteProduct(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}