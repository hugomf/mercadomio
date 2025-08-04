import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/category_service.dart';
import '../services/category_events.dart';
import 'dart:async';

class CategorySelector extends StatefulWidget {
  final Function() onSelectionChanged;

  const CategorySelector({super.key, required this.onSelectionChanged});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late final CategoryService categoryService;
  late final Future<void> _categoriesFuture;
  late final StreamSubscription<CategorySelectionEvent> _categorySub;
  final Rx<CategorySelectionEvent> _currentSelection = CategorySelectionEvent(
    selectedIds: [],
    selectedNames: [],
    isAllSelected: true,
  ).obs;

  @override
  void initState() {
    super.initState();
    categoryService = Get.find<CategoryService>();
    _categoriesFuture = categoryService.getCategories();
    _categorySub = CategoryEventBus.stream.listen((event) {
      _currentSelection.value = event;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _categorySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Obx(() => _buildCategoryList());
      },
    );
  }

  Widget _buildCategoryList() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: categoryService.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAllSelected = _currentSelection.value.isAllSelected;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  categoryService.addSelectedCategory(
                    CategoryService.allCategoriesId,
                    CategoryService.allCategoriesName
                  );
                  widget.onSelectionChanged();
                  setState(() {});
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  margin: const EdgeInsets.only(right: 4.0),
                  decoration: BoxDecoration(
                    color: isAllSelected ? Colors.deepPurple : Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isAllSelected ? Colors.deepPurple : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    'All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isAllSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }

          final categoryIndex = index - 1;
          final category = categoryService.categories[categoryIndex];
          final isSelected = _currentSelection.value.selectedIds.contains(category.id) &&
            !_currentSelection.value.isAllSelected;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                categoryService.addSelectedCategory(category.id, category.name);
                widget.onSelectionChanged();
                setState(() {});
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}