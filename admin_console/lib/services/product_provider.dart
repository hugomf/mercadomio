import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _apiService.getProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProduct = await _apiService.createProduct(product);
      _products.add(newProduct);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProduct = await _apiService.updateProduct(id, product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      return await _apiService.searchProducts(query);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}