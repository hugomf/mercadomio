import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models/user.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['data']?['token'] ?? json['token'],
      user: User.fromJson(json['data']?['user'] ?? json['user']),
    );
  }
}

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxString _token = ''.obs;
  final RxBool _isLoading = false.obs;

  User? get currentUser => _currentUser.value;
  String? get token => _token.value;
  bool get isAuthenticated => _token.isNotEmpty && _currentUser.value != null;
  bool get isLoading => _isLoading.value;

  Future<String> _getApiUrl() async {
    await dotenv.load();
    return dotenv.env['API_URL'] ?? 'http://localhost:8080';
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

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    try {
      _isLoading.value = true;
      final apiUrl = await _getApiUrl();

      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'type': userType.toString().split('.').last.toLowerCase(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        final authResponse = AuthResponse.fromJson(responseData);
        _saveAuthData(authResponse);
        return true;
      } else {
        final message = responseData['message'] ?? 'Registration failed';
        throw message;
      }
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      final apiUrl = await _getApiUrl();

      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final authResponse = AuthResponse.fromJson(responseData);
        _saveAuthData(authResponse);
        return true;
      } else {
        final message = responseData['message'] ?? 'Login failed';
        throw message;
      }
    } catch (e) {
      throw e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> logout() async {
    // Clear local auth data
    await _clearAuthData();

    // Optionally call logout endpoint
    try {
      final apiUrl = await _getApiUrl();
      await http.post(
        Uri.parse('$apiUrl/api/auth/logout'),
        headers: authHeaders,
      );
    } catch (e) {
      // Ignore logout endpoint errors
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

  void _saveAuthData(AuthResponse authResponse) {
    _token.value = authResponse.token;
    _currentUser.value = authResponse.user;

    // Save to persistent storage if needed
    // For now, token will be lost on app restart
    // TODO: Implement secure storage for token persistence
  }

  Future<void> _clearAuthData() async {
    _token.value = '';
    _currentUser.value = null;

    // Clear from persistent storage if needed
  }

  // Initialize service - check for existing auth on app start
  Future<void> init() async {
    // Check for stored token and validate it
    // For now, no persistence - user will need to login each time
    // TODO: Implement token persistence
  }
}
