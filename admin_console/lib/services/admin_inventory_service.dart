import 'dart:convert';
import 'admin_auth_service.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';

// Admin inventory service - lists products and updates variant stock.
class AdminInventoryService {
  final String baseUrl;
  final String? authToken;

  AdminInventoryService({
    this.baseUrl = 'http://localhost:8080',
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if ((authToken ?? AdminAuthService.instance.token) != null)
            'Authorization': 'Bearer ${authToken ?? AdminAuthService.instance.token}',
      };

  // GET /api/products?page&limit&sort&order
  Future<ProductsPage> getProducts({
    int page = 1,
    int limit = 100,
    String sort = 'name',
    String order = 'asc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    };
    final uri = Uri.parse('$baseUrl/api/products')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return ProductsPage.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response, 'Failed to load products'));
  }

  // POST /api/products — create a new product (admin)
  Future<Product> createProduct({
    required String name,
    required double basePrice,
    required String sku,
    String? imageUrl,
    List<ProductVariant>? variants,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'basePrice': basePrice,
      'sku': sku,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (variants != null) 'variants': variants.map((v) => v.toJson()).toList(),
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/products'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response, 'Failed to create product'));
  }

  // DELETE /api/products/:id — delete a product (admin)
  Future<void> deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to delete product'));
    }
  }

  // PUT /api/products/:id/variants/:variantId/stock
  Future<void> updateStock(String productId, String variantId, int stock) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/products/$productId/variants/$variantId/stock'),
      headers: _headers,
      body: jsonEncode({'stock': stock}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update stock'));
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final error = jsonDecode(response.body)['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'];
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}

// Admin category service - manages categories via the backend API.
class AdminCategoryService {
  final String baseUrl;
  final String? authToken;

  AdminCategoryService({
    this.baseUrl = 'http://localhost:8080',
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if ((authToken ?? AdminAuthService.instance.token) != null)
            'Authorization': 'Bearer ${authToken ?? AdminAuthService.instance.token}',
      };

  // GET /api/categories
  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception(_errorMessage(response, 'Failed to load categories'));
  }

  // POST /api/categories — create a new category (admin)
  Future<Category> createCategory({
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null) 'description': description,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/categories'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response, 'Failed to create category'));
  }

  // PUT /api/categories/:id — update a category (admin)
  Future<Category> updateCategory(String id, String name, String? description) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null) 'description': description,
    };
    final response = await http.put(
      Uri.parse('$baseUrl/api/categories/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response, 'Failed to update category'));
  }

  // DELETE /api/categories/:id — delete a category (admin)
  Future<void> deleteCategory(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/categories/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to delete category'));
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final error = jsonDecode(response.body)['error'];
      if (error is Map<String, dynamic> && error['message'] != null) {
        return error['message'];
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
}