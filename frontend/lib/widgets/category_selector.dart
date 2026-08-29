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

  /// Maps category names to Material icons, matching the Stitch mock.
  static const Map<String, IconData> _categoryIcons = {
    'Frutas y Verduras': Icons.local_florist,
    'Frutas': Icons.local_florist,
    'Verduras': Icons.local_florist,
    'Lácteos': Icons.water_drop,
    'Carnicería': Icons.set_meal,
    'Panadería': Icons.bakery_dining,
    'Abarrotes': Icons.kitchen,
    'Bebidas': Icons.local_bar,
    'Orgánicos': Icons.eco,
    'Ofertas': Icons.local_offer,
    'All': Icons.category,
  };

  /// Returns the icon for a category, falling back to a generic icon.
  IconData _getIconForCategory(String categoryName, String categoryId) {
    return _categoryIcons[categoryName] ??
        _categoryIcons[categoryId] ??
        Icons.category;
  }

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
            height: 44,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Obx(() => _buildCategoryList());
      },
    );
  }

  Widget _buildCategoryList() {
    return Container(
      height: 44,
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
              child: _buildPill(
                icon: _getIconForCategory(
                  CategoryService.allCategoriesName,
                  CategoryService.allCategoriesId,
                ),
                label: 'Todos',
                selected: isAllSelected,
                onTap: () {
                  categoryService.addSelectedCategory(
                    CategoryService.allCategoriesId,
                    CategoryService.allCategoriesName,
                  );
                  widget.onSelectionChanged();
                  setState(() {});
                },
              ),
            );
          }

          final categoryIndex = index - 1;
          final category = categoryService.categories[categoryIndex];
          final isSelected = _currentSelection.value.selectedIds
                  .contains(category.id) &&
              !_currentSelection.value.isAllSelected;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildPill(
              icon: _getIconForCategory(category.name, category.id),
              label: category.name,
              selected: isSelected,
              onTap: () {
                categoryService.addSelectedCategory(
                  category.id,
                  category.name,
                );
                widget.onSelectionChanged();
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds a single category pill matching the Stitch mobile mock.
  Widget _buildPill({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          // Selected → primaryContainer (Stitch bg-primary-container)
          // Unselected → surfaceContainer with hover (Stitch bg-surface-container)
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          border: selected
              ? null
              : Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
