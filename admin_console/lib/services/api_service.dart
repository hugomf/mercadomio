import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import 'config_service.dart';

class ApiService {
  static String get baseUrl => ConfigService.apiBaseUrl;
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Headers for API requests
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Error handling
  void _handleError(dynamic error) {
    // ignore: avoid_print
    print('API Error: $error');
    // You can add more sophisticated error handling here
    throw Exception('Failed to communicate with server');
  }

  // Product API methods
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  Future<Product> getProduct(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: headers,
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  // Category API methods
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  Future<Category> getCategory(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load category: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  Future<Category> createCategory(Category category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 201) {
        return Category.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create category: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  Future<Category> updateCategory(String id, Category category) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update category: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      rethrow;
    }
  }

  // Search methods
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/search?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  // Image upload method (placeholder - implement based on your backend)
  Future<String> uploadImage(List<int> imageBytes, String fileName) async {
    // This is a placeholder - implement actual image upload logic
    // based on your backend's image upload endpoint
    return 'https://example.com/images/$fileName';
  }
}