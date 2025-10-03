import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = Get.find<AuthService>();
  final _isLoading = false.obs;
  final _isLogin = true.obs; // true for login, false for register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin.value) {
        // Login
        final success = await _authService.login(
          email: email,
          password: password,
        );

        if (success) {
          Get.snackbar(
            'Success',
            'Login successful!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Navigate to main screen
          Get.offAllNamed('/');
        }
      } else {
        // For now, navigate to home after "register"
        // In a real app, this would register the user
        Get.snackbar(
          'Success',
          'Registration successful!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // TODO: Implement register flow
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _toggleMode() {
    _isLogin.value = !_isLogin.value;
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Obx(() => Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title
                const Center(
                  child: Text(
                    'Mercado Mío',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isLogin.value ? 'Sign In' : 'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading.value ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_isLogin.value ? 'Sign In' : 'Create Account'),
                ),

                const SizedBox(height: 16),

                // Toggle Mode
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    _isLogin.value
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Sign In',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),

                const SizedBox(height: 24),

                // Demo Account Hint
                const Center(
                  child: Text(
                    'Demo: Use any email/password to sign in',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}
