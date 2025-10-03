import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authService = Get.find<AuthService>();
      if (authService.isAuthenticated) {
        return child;
      } else {
        return const LoginScreen();
      }
    });
  }
}

// Utility function to check authentication and redirect if needed
void checkAuthAndRedirect() {
  final authService = AuthService.to;

  if (!authService.isAuthenticated) {
    Get.offAll(() => const AuthGuard(child: SizedBox()));
  }
}

// Auth state listener widget that can wrap entire app
class AuthStateListener extends StatelessWidget {
  final Widget child;

  const AuthStateListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    // Listen to auth state changes
    return Obx(() {
      // This widget rebuilds when auth state changes
      return child;
    });
  }
}

// Auth-required guard that redirects to login if not authenticated
class AuthRequired extends StatelessWidget {
  final Widget child;
  final Widget? loginWidget;

  const AuthRequired({
    super.key,
    required this.child,
    this.loginWidget,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Obx(() {
      if (authService.isAuthenticated) {
        return child;
      } else {
        return loginWidget ?? const LoginScreen();
      }
    });
  }
}

// Optional auth - shows different content based on auth state
class AuthOptional extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;

  const AuthOptional({
    super.key,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Obx(() {
      if (authService.isAuthenticated) {
        return authenticatedChild;
      } else {
        return unauthenticatedChild;
      }
    });
  }
}
