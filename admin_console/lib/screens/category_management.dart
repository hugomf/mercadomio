import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _buildCategoryTree(),
    );
  }

  Widget _buildCategoryTree() {
    // Build hierarchy from flat list
    final rootCategories = _categories.where((c) => c.isRoot).toList();
    final categoryMap = {for (var c in _categories) c.id: c};

    return ListView.builder(
      itemCount: rootCategories.length,
      itemBuilder: (context, index) {
        return _buildCategoryNode(rootCategories[index], categoryMap);
      },
    );
  }

  Widget _buildCategoryNode(Category category, Map<String, Category> categoryMap) {
    final children = _categories.where((c) => c.parentId == category.id).toList();
    
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: Text(category.name),
      subtitle: Text(category.description ?? ''),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              if (children.isNotEmpty)
                ...children.map((child) =>
                  _buildCategoryNode(child, categoryMap)
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditCategoryDialog(category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(category.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddSubCategoryDialog(category),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog({Category? parent}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final parentId = parent?.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
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
                setState(() {
                  final newId = DateTime.now().millisecondsSinceEpoch.toString();
                  final newCategory = Category(
                    id: newId,
                    name: nameController.text,
                    description: descController.text,
                    parentId: parentId,
                    path: parent != null
                      ? '${parent.path}$newId/'
                      : '/$newId/',
                    depth: parent != null ? parent.depth + 1 : 1,
                  );
                  _categories.add(newCategory);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSubCategoryDialog(Category parent) {
    _showAddCategoryDialog(parent: parent);
  }

  void _showEditCategoryDialog(Category category) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(text: category.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
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
                setState(() {
                  final index = _categories.indexWhere(
                    (c) => c.id == category.id);
                  if (index != -1) {
                    _categories[index] = Category(
                      id: category.id,
                      name: nameController.text,
                      description: descController.text,
                      imageUrl: category.imageUrl,
                      path: category.path,
                      depth: category.depth,
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String id) {
    setState(() {
      _categories.removeWhere((cat) => cat.id == id);
    });
  }
}