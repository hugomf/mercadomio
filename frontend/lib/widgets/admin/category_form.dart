import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/category.dart' as category_model;
import '../../services/category_service.dart';

class CategoryForm extends StatefulWidget {
  final category_model.Category? category;
  final category_model.Category? parentCategory;

  const CategoryForm({super.key, this.category, this.parentCategory});

  @override
  CategoryFormState createState() => CategoryFormState();
}

class CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CategoryService _categoryService = Get.find();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Category Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a category name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text(widget.category == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final category = widget.category ?? category_model.Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
      );
      category.name = _nameController.text;
      category.description = _descriptionController.text;
      category.parentId = widget.parentCategory?.id;

      try {
        if (widget.category == null) {
          await _categoryService.createCategory(category);
        } else {
          await _categoryService.updateCategory(category);
        }
        Get.back(result: true);
      } catch (e) {
        Get.snackbar('Error', 'Failed to save category: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}