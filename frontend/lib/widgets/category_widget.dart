import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/category_service.dart';

class CategoryWidget extends StatelessWidget {
  const CategoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryService categoryService = Get.find();
    return Obx(() {
      final categories = categoryService.getRootCategories();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...categories.map((category) => 
            CategoryItem(
              category: category,
              depth: 0,
            ),
          ),
        ],
      );
    });
  }
}

class CategoryItem extends StatefulWidget {
  final Category category;
  final int depth;

  const CategoryItem({
    super.key,
    required this.category,
    required this.depth,
  });

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final CategoryService categoryService = Get.find();
    final hasChildren = widget.category.children.isNotEmpty;
    final isSelected = categoryService.selectedCategoryId.value == widget.category.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            categoryService.selectedCategoryId.value = widget.category.id;
          },
          onLongPress: hasChildren ? () {
            setState(() {
              _expanded = !_expanded;
            });
          } : null,
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (widget.depth * 16.0),
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.deepPurple.withOpacity(0.1)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    _expanded 
                      ? Icons.expand_more 
                      : Icons.chevron_right,
                    size: 20,
                  ),
                if (!hasChildren)
                  const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: TextStyle(
                      fontWeight: isSelected 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded && hasChildren)
          ...widget.category.children.map((child) => 
            CategoryItem(
              category: child,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }
}