import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Category {
  final String id;
  final String name;
  final String? parentId;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
      parentId: json['parentId'],
      children: (json['children'] as List? ?? [])
          .map((child) => Category.fromJson(child))
          .toList(),
    );
  }
}

class CategoryService extends GetxService {
  final RxList<Category> categories = <Category>[].obs;
  final RxString selectedCategoryId = ''.obs;

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        categories.value = data.map((cat) => Category.fromJson(cat)).toList();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories');
    }
  }

  List<Category> getRootCategories() {
    return categories.where((cat) => cat.parentId == null).toList();
  }

  List<Category> getChildCategories(String parentId) {
    return categories.where((cat) => cat.parentId == parentId).toList();
  }
}