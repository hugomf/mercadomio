import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme.dart';
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

  /// Whether the password field is hidden (matches the Stitch visibility toggle).
  bool _obscurePassword = true;

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
            '¡Bienvenido!',
            'Inicio de sesión exitoso',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );

          // Navigate to main screen
          Get.offAllNamed('/');
        }
      } else {
        // For now, navigate to home after "register"
        // In a real app, this would register the user
        Get.snackbar(
          '¡Listo!',
          'Registro exitoso',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        // TODO: Implement register flow
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _toggleMode() {
    _isLogin.value = !_isLogin.value;
    _formKey.currentState?.reset();
  }

  /// Returns to the storefront. Pops the current route if one exists,
  /// otherwise falls back to the home screen.
  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      Get.offAllNamed('/');
    }
  }

  /// Small back button shown at the top-left corner so the user can
  /// return to the storefront without navigating away.
  Widget _backButton() {
    return Positioned(
      top: 8,
      left: 8,
      child: IconButton(
        tooltip: 'Volver a la tienda',
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Obx(() => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBrandHeader(colorScheme),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: _buildFormCard(colorScheme),
                        ),
                      ],
                    )),
                  ),
                ),
              ),
              _backButton(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Obx(() => Form(
                    key: _formKey,
                    child: _buildMobileForm(colorScheme),
                  )),
                ),
              ),
            ),
            _backButton(),
          ],
        ),
      ),
    );
  }

  /// Brand mark displayed above the login card on wide screens.
  Widget _buildBrandHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag,
            size: 26,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Mercadomio',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Desktop (>=800px) login card layout.
  Widget _buildFormCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              _isLogin.value ? 'Iniciar sesión' : 'Crear cuenta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Ingresa a tu cuenta para continuar',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              if (!GetUtils.isEmail(value)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading.value ? null : _toggleMode,
              child: Text(
                _isLogin.value ? '¿Olvidaste tu contraseña?' : '¿Ya tienes cuenta? Inicia sesión',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading.value ? null : _submitForm,
            icon: _isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.login),
            label: Text(
              _isLogin.value ? 'Iniciar sesión' : 'Crear cuenta',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Divider with "o"
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isLoading.value ? null : _toggleMode,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outline, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            icon: const Icon(Icons.person_add_alt),
            label: Text(
              _isLogin.value ? 'Crear cuenta nueva' : 'Iniciar sesión',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile (<800px) login form layout.
  Widget _buildMobileForm(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand logo/title
        const Center(
          child: Text(
            'Mercadomio',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Icon(
            Icons.shopping_bag,
            size: 40,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            _isLogin.value ? 'Ingresa a tu cuenta' : 'Crea tu cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa tu correo electrónico';
            }
            if (!GetUtils.isEmail(value)) {
              return 'Ingresa un correo válido';
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
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Submit Button
        ElevatedButton(
          onPressed: _isLoading.value ? null : _submitForm,
          child: _isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isLogin.value ? 'Ingresar' : 'Crear cuenta'),
        ),
        const SizedBox(height: 16),
        // Toggle Mode
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isLogin.value
                ? '¿No tienes cuenta? Regístrate'
                : '¿Ya tienes cuenta? Inicia sesión',
          ),
        ),
        const SizedBox(height: 24),
        // Demo Account Hint
        const Center(
          child: Text(
            'Demo: usa cualquier correo y contraseña',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}