import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models/product.dart';
import 'config_service.dart';

class ProductService extends GetxService {
  static ProductService get to => Get.find();

  final ConfigService configService = Get.find();

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final apiUrl = await configService.getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/products/$productId/reviews'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> reviewsData = json.decode(response.body);
        return reviewsData.map((review) => Review.fromJson(review)).toList();
      } else {
        throw Exception('Failed to load product reviews');
      }
    } catch (e) {
      throw Exception('Error fetching product reviews: $e');
    }
  }

  Future<List<Product>> getRelatedProducts(String productId) async {
    try {
      final apiUrl = await configService.getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/products/$productId/related'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsData = json.decode(response.body);
        return productsData.map((product) => Product.fromJson(product)).toList();
      } else {
        throw Exception('Failed to load related products');
      }
    } catch (e) {
      throw Exception('Error fetching related products: $e');
    }
  }

  Future<Product> getProductDetails(String productId) async {
    try {
      final apiUrl = await configService.getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/products/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> productData = json.decode(response.body);
        return Product.fromJson(productData);
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }
}
