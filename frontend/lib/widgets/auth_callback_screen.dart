import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme.dart';
import '../services/auth_service.dart';

/// Handles the OIDC redirect back from userbrew at /auth/callback.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    final params = Uri.base.queryParameters;
    try {
      final ok = await Get.find<AuthService>().handleCallback(
        code: params['code'],
        state: params['state'],
        error: params['error'],
      );

      if (!mounted) return;
      if (ok) {
        Get.offAllNamed('/');
      } else {
        setState(() => _error = 'No se pudo cargar tu perfil');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Completando inicio de sesión...',
                  style: Theme.of(context).textTheme.bodyLarge),
            ] else ...[
              const Icon(Icons.error_outline, size: 48,
                  color: AppTheme.error),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Get.offAllNamed('/'),
                child: const Text('Volver a la tienda'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
