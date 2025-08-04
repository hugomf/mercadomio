import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product.dart';
import './category_events.dart';
import 'dart:convert';
import '../models/category.dart' as models;

class CategoryService extends GetxController {
  static const String allCategoriesId = 'ALL_CATEGORIES';
  static const String allCategoriesName = 'All';
  final RxList<models.Category> categories = <models.Category>[].obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxList<String> selectedCategoryNames = <String>[].obs;
  // Backward compatibility
  final RxString selectedCategoryName = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  Future<String> getApiUrl() async {
    await dotenv.load();
    return dotenv.env['API_URL'] ?? 'http://localhost:8080';
  }

  Future<void> createCategory(models.Category category) async {
    try {
      final apiUrl = await getApiUrl();
      final response = await http.post(
        Uri.parse('$apiUrl/api/categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );
      if (response.statusCode == 201) {
        final newCategory = models.Category.fromJson(json.decode(response.body));
        categories.add(newCategory);
        update();
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create category');
      rethrow;
    }
  }

  Future<void> updateCategory(models.Category category) async {
    try {
      final apiUrl = await getApiUrl();
      final response = await http.put(
        Uri.parse('$apiUrl/api/categories/${category.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );
      if (response.statusCode == 200) {
        final index = categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          categories[index] = category;
          update();
        }
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update category');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final apiUrl = await getApiUrl();
      final response = await http.delete(
        Uri.parse('$apiUrl/api/categories/$id'),
      );
      if (response.statusCode == 204) {
        categories.removeWhere((c) => c.id == id);
        update();
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category');
      rethrow;
    }
  }

  Future<List<models.Category>> getRootCategories() async {
    await getCategories();
    return categories.where((c) => c.parentId == null).toList();
  }

  Future<List<models.Category>> getCategories() async {
    try {
      final apiUrl = await getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/api/categories'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<models.Category> loadedCategories = jsonData
          .map((json) => models.Category.fromJson(json))
          .toList();
        
        categories.assignAll(loadedCategories);
        
        // Select "All" by default if nothing is selected
        if (selectedCategories.isEmpty) {
          addSelectedCategory(allCategoriesId, allCategoriesName);
        }
        
        return loadedCategories;
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories');
      rethrow;
    }
  }

  Future<List<models.Category>> getChildCategories(String parentId) async {
    await getCategories();
    return categories.where((c) => c.parentId == parentId).toList();
  }

  void addSelectedCategory(String id, String name) {
    if (id == allCategoriesId) {
      // Selecting "All" clears other selections
      selectedCategories
        ..clear()
        ..add(id);
      selectedCategoryNames
        ..clear()
        ..add(name);
      selectedCategoryName.value = name;
      selectedCategoryId.value = id;
    } else {
      // Selecting a regular category
      if (selectedCategories.contains(allCategoriesId)) {
        // Clear "All" if it was selected
        selectedCategories.remove(allCategoriesId);
        selectedCategoryNames.remove(allCategoriesName);
      }
      // Toggle selection
      if (selectedCategories.contains(id)) {
        selectedCategories.remove(id);
        selectedCategoryNames.remove(name);
      } else {
        selectedCategories.add(id);
        selectedCategoryNames.add(name);
      }
      // Update single selection for backward compatibility
      if (selectedCategories.isNotEmpty) {
        selectedCategoryName.value = name;
        selectedCategoryId.value = id;
      } else {
        selectedCategoryName.value = '';
        selectedCategoryId.value = '';
      }
    }
    _publishSelectionEvent();
    update();
  }

  void _publishSelectionEvent() {
    CategoryEventBus.publish(
      CategorySelectionEvent(
        selectedIds: selectedCategories.toList(),
        selectedNames: selectedCategoryNames.toList(),
        isAllSelected: isAllSelected(),
      ),
    );
  }

  void removeSelectedCategory(String id) {
    selectedCategories.remove(id);
    selectedCategoryNames.removeWhere((name) =>
      categories.firstWhere((c) => c.id == id).name == name);
    // Backward compatibility
    if (selectedCategories.isEmpty) {
      selectedCategoryName.value = '';
      selectedCategoryId.value = '';
    }
    update();
  }

  void clearSelectedCategories() {
    selectedCategories
      ..clear()
      ..add(allCategoriesId);
    selectedCategoryNames
      ..clear()
      ..add(allCategoriesName);
    // Backward compatibility
    selectedCategoryName.value = allCategoriesName;
    selectedCategoryId.value = allCategoriesId;
    update();
  }

  bool isAllSelected() {
    return selectedCategories.contains(allCategoriesId);
  }

  String? getCategoryFilterQuery() {
    if (selectedCategories.isEmpty || isAllSelected()) {
      return null;
    }
    return selectedCategoryNames.join(',');
  }

  Future<Map<String, dynamic>> getFilteredProducts({
    required String apiUrl,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    String sortBy = 'name',
    bool sortAscending = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sortBy,
        'order': sortAscending ? 'asc' : 'desc',
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      if (!isAllSelected() && selectedCategories.isNotEmpty) {
        queryParams['category'] = selectedCategoryNames.join(',');
      }

      final uri = Uri.parse('$apiUrl/api/products').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        return {
          'products': data.map((json) => Product.fromJson(json)).toList(),
          'total': decoded['total'] ?? 0
        };
      }
      throw Exception('Failed to load products');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products');
      rethrow;
    }
  }

  @override
  void onClose() {
    categories.close();
    selectedCategories.close();
    selectedCategoryNames.close();
    selectedCategoryId.close();
    super.onClose();
  }
}