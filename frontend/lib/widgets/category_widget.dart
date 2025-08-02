import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/category_service.dart';
import '../models/category.dart' as models;

class CategoryWidget extends StatelessWidget {
  const CategoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryService>(
      builder: (categoryService) {
        return FutureBuilder<List<models.Category>>(
          future: categoryService.getRootCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }
            return Column(
              children: [
                ...snapshot.data!.map((category) => _CategoryItem(
                  category: category,
                  categoryService: categoryService,
                )),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final models.Category category;
  final CategoryService categoryService;

  const _CategoryItem({
    required this.category,
    required this.categoryService
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.childrenIds?.isNotEmpty ?? false;
    
    return Column(
      children: [
        ListTile(
          title: Text(category.name),
          onTap: () {
            categoryService.selectedCategoryId.value = category.id;
          },
        ),
        if (hasChildren)
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: FutureBuilder<List<models.Category>>(
              future: categoryService.getCategories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox.shrink();
                }
                final children = snapshot.data!
                  .where((c) => category.childrenIds!.contains(c.id))
                  .toList();
                return Column(
                  children: children.map((child) => _CategoryItem(
                    category: child,
                    categoryService: categoryService,
                  )).toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}