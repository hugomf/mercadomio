import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import 'oidc_flow.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxString _token = ''.obs;
  final RxBool _isLoading = false.obs;

  OidcFlow? _flow;
  final _storage = GetStorage('auth');

  User? get currentUser => _currentUser.value;
  String? get token => _token.value;
  bool get isAuthenticated => _token.isNotEmpty && _currentUser.value != null;
  bool get isLoading => _isLoading.value;

  // TEMP: used only by the screenshot compare entry point to inject a test token.
  void setTokenForCompare(String t) => _token.value = t;

  Future<String> _getApiUrl() async {
    await dotenv.load();
    return dotenv.env['API_URL'] ?? 'http://localhost:8080';
  }

  OidcConfig get _oidcConfig {
    return OidcConfig(
      issuer: dotenv.env['USERBREW_ISSUER'] ?? 'http://localhost:8090',
      clientId: dotenv.env['USERBREW_CLIENT_ID'] ?? 'mercadomio-storefront',
      redirectUri:
          dotenv.env['USERBREW_REDIRECT_URI'] ?? 'http://localhost:3000/auth/callback',
    );
  }

  OidcFlow get flow {
    _flow ??= OidcFlow(
      config: _oidcConfig,
      httpClient: http.Client(),
      openBrowser: (uri) async {
        if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
          throw const OidcException('No se pudo abrir el navegador');
        }
      },
    );
    return _flow!;
  }

  Map<String, String> get authHeaders {
    if (token != null && token!.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  /// Redirects the browser to the userbrew hosted login UI.
  Future<bool> login() async {
    try {
      _isLoading.value = true;
      await flow.startLogin();
      return true;
    } on OidcException catch (e) {
      throw e.message;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Handles the /auth/callback redirect: exchanges the code, persists the
  /// session and loads the profile from the backend (which upserts the user).
  Future<bool> handleCallback({
    String? code,
    String? state,
    String? error,
  }) async {
    try {
      _isLoading.value = true;

      final session =
          await flow.handleCallback(code: code, state: state, error: error);

      _token.value = session.accessToken;
      _storage.write('accessToken', session.accessToken);
      _storage.write('refreshToken', session.refreshToken);

      final profile = await getProfile();
      return profile != null;
    } on OidcException catch (e) {
      throw e.message;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> logout() async {
    // Clear local auth data
    await _clearAuthData();

    try {
      final apiUrl = await _getApiUrl();
      await http.get(
        Uri.parse('$apiUrl/api/auth/profile'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      // Ignore backend errors during logout.
    }

    return true;
  }

  Future<User?> getProfile() async {
    if (!isAuthenticated) return null;

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/auth/profile'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final user = User.fromJson(responseData['user']);
        _currentUser.value = user;
        return user;
      } else {
        // Token might be invalid, clear auth data
        await _clearAuthData();
        return null;
      }
    } catch (e) {
      // If request fails, treat as unauthenticated
      await _clearAuthData();
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) return false;

    try {
      _isLoading.value = true;
      final apiUrl = await _getApiUrl();

      final response = await http.put(
        Uri.parse('$apiUrl/api/auth/profile'),
        headers: authHeaders,
        body: json.encode(updates),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final updatedUser = User.fromJson(responseData['user']);
        _currentUser.value = updatedUser;
        return true;
      } else {
        throw responseData['message'] ?? 'Update failed';
      }
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> verifyToken() async {
    if (!isAuthenticated) return false;

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/auth/verify'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      return response.statusCode == 200 &&
             responseData['success'] == true &&
             responseData['user'] != null;

    } catch (e) {
      return false;
    }
  }

  Future<void> _clearAuthData() async {
    _token.value = '';
    _currentUser.value = null;
    await _storage.remove('accessToken');
    await _storage.remove('refreshToken');
  }

  // Initialize service - restore persisted session on app start.
  Future<void> init() async {
    final stored = _storage.read<String>('accessToken');
    if (stored != null && stored.isNotEmpty) {
      _token.value = stored;
      await getProfile();
    }
  }

  // User shopping profile methods
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    if (!isAuthenticated) return [];

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/auth/addresses'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return List<Map<String, dynamic>>.from(responseData['addresses'] ?? []);
      } else {
        throw responseData['message'] ?? 'Failed to get addresses';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> addUserAddress(Map<String, dynamic> addressData) async {
    if (!isAuthenticated) return false;

    try {
      _isLoading.value = true;
      final apiUrl = await _getApiUrl();

      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/addresses'),
        headers: authHeaders,
        body: json.encode(addressData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return true;
      } else {
        throw responseData['message'] ?? 'Failed to add address';
      }
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPaymentMethods() async {
    if (!isAuthenticated) return [];

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/auth/payment-methods'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return List<Map<String, dynamic>>.from(responseData['paymentMethods'] ?? []);
      } else {
        throw responseData['message'] ?? 'Failed to get payment methods';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> addUserPaymentMethod(Map<String, dynamic> paymentMethodData) async {
    if (!isAuthenticated) return false;

    try {
      _isLoading.value = true;
      final apiUrl = await _getApiUrl();

      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/payment-methods'),
        headers: authHeaders,
        body: json.encode(paymentMethodData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return true;
      } else {
        throw responseData['message'] ?? 'Failed to add payment method';
      }
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<List<String>> getUserWishlist() async {
    if (!isAuthenticated) return [];

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.get(
        Uri.parse('$apiUrl/api/auth/wishlist'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return List<String>.from(responseData['wishlist'] ?? []);
      } else {
        throw responseData['message'] ?? 'Failed to get wishlist';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> addToWishlist(String productId) async {
    if (!isAuthenticated) return false;

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/wishlist/$productId'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return true;
      } else {
        throw responseData['message'] ?? 'Failed to add to wishlist';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> removeFromWishlist(String productId) async {
    if (!isAuthenticated) return false;

    try {
      final apiUrl = await _getApiUrl();

      final response = await http.delete(
        Uri.parse('$apiUrl/api/auth/wishlist/$productId'),
        headers: authHeaders,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return true;
      } else {
        throw responseData['message'] ?? 'Failed to remove from wishlist';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
