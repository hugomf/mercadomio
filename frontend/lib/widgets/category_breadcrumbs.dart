import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/category_service.dart';

class CategoryBreadcrumbs extends StatelessWidget {
  final VoidCallback onBreadcrumbTap;

  const CategoryBreadcrumbs({super.key, required this.onBreadcrumbTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final CategoryService categoryService = Get.find<CategoryService>();

    return Obx(() {
      // Don't show breadcrumbs if "All" is selected
      if (categoryService.isAllSelected()) {
        return const SizedBox.shrink();
      }

      final selectedCategoryIds = categoryService.selectedCategories;
      final selectedCategoryNames = categoryService.selectedCategoryNames;

      if (selectedCategoryIds.isEmpty || selectedCategoryNames.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colorScheme.surfaceContainer,
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                children: [
                  // "All" breadcrumb
                  GestureDetector(
                    onTap: () {
                      categoryService.clearSelectedCategories();
                      onBreadcrumbTap();
                    },
                    child: Text(
                      'Todos',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  // Arrow separator
                  if (selectedCategoryNames.isNotEmpty) ...[
                    Text(
                      ' > ',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  // Category breadcrumbs
                  ...selectedCategoryNames.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoryName = entry.value;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Remove this category and all after it
                            categoryService.removeCategoriesFromIndex(index);
                            onBreadcrumbTap();
                          },
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        // Arrow separator (except for last item)
                        if (index < selectedCategoryNames.length - 1) ...[
                          Text(
                            ' > ',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
