import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/category.dart' as models;

class CategoryService extends GetxController {
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
        return loadedCategories;
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('[ERROR] Failed to load categories: $e');
      Get.snackbar('Error', 'Failed to load categories');
      rethrow;
    }
  }

  Future<List<models.Category>> getChildCategories(String parentId) async {
    await getCategories();
    return categories.where((c) => c.parentId == parentId).toList();
  }

  void addSelectedCategory(String id, String name) {
    if (!selectedCategories.contains(id)) {
      selectedCategories.add(id);
      selectedCategoryNames.add(name);
      // Backward compatibility
      selectedCategoryName.value = name;
      selectedCategoryId.value = id;
      update();
    }
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
    selectedCategories.clear();
    selectedCategoryNames.clear();
    // Backward compatibility
    selectedCategoryName.value = '';
    selectedCategoryId.value = '';
    update();
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