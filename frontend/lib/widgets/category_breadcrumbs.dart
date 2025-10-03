import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/category_service.dart';

class CategoryBreadcrumbs extends StatelessWidget {
  final VoidCallback onBreadcrumbTap;

  const CategoryBreadcrumbs({super.key, required this.onBreadcrumbTap});

  @override
  Widget build(BuildContext context) {
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
        color: Colors.grey[50],
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey,
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
                    child: const Text(
                      'All',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  // Arrow separator
                  if (selectedCategoryNames.isNotEmpty) ...[
                    const Text(
                      ' > ',
                      style: TextStyle(
                        color: Colors.grey,
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
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        // Arrow separator (except for last item)
                        if (index < selectedCategoryNames.length - 1) ...[
                          const Text(
                            ' > ',
                            style: TextStyle(
                              color: Colors.grey,
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
