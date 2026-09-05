import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'footer.dart';

/// Login screen matching the Stitch mocks:
/// — Desktop (`login-desktop.html`): brand header (logo + wordmark) above a
///   440px card (title "Iniciar sesión" + subtitle), primary CTA, divider
///   "o" and an outlined "Crear cuenta nueva" CTA, with the app footer.
/// — Mobile (`login.html`): "¡Hola!" brand header above a card with a
///   primary→secondary gradient accent bar, the same CTAs and the footer.
///
/// Auth stays as decided in the userbrew OIDC design: both CTAs redirect to
/// the userbrew hosted UI (password / Google / registration), so no native
/// email/password form is rendered.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = Get.find<AuthService>();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.login();
      // Browser navigation away from the page happens inside login().
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return isDesktop ? _buildDesktop(context) : _buildMobile(context);
  }

  // ---------------------------------------------------------------- desktop

  Widget _buildDesktop(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBrandHeader(colorScheme),
                      const SizedBox(height: 32),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildDesktopCard(colorScheme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  /// Centered logo + wordmark row, matching the mock's `w-12` logo and
  /// `text-3xl font-black text-primary tracking-tight` wordmark.
  Widget _buildBrandHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Text(
          'Mercadomio',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar sesión',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa a tu cuenta para continuar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(colorScheme, radius: 8),
          _buildDivider(colorScheme, 'o'),
          _buildCreateAccountButton(
            colorScheme,
            radius: 8,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: colorScheme.outline, width: 2),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- mobile

  Widget _buildMobile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    _buildMobileBrandHeader(colorScheme),
                    const SizedBox(height: 24),
                    _buildMobileCard(colorScheme),
                  ],
                ),
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  /// Logo + "¡Hola!" + subtitle, matching the mobile mock's brand header.
  Widget _buildMobileBrandHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(
          '¡Hola!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para continuar comprando tus productos frescos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  /// Card with the gradient accent bar (`rounded-2xl`, border, soft shadow).
  Widget _buildMobileCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPrimaryButton(colorScheme, radius: 12),
                _buildDivider(colorScheme, 'O'),
                _buildCreateAccountButton(
                  colorScheme,
                  radius: 12,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ shared bits

  Widget _buildPrimaryButton(ColorScheme colorScheme, {required double radius}) {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _signIn,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      icon: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.login),
      label: const Text('Iniciar sesión'),
    );
  }

  /// "o" separator with lines on both sides (mock `.border-t` + label).
  Widget _buildDivider(ColorScheme colorScheme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  /// Outlined "Crear cuenta nueva" CTA — also redirects to the userbrew
  /// hosted UI, which offers the registration/enrollment flow.
  Widget _buildCreateAccountButton(
    ColorScheme colorScheme, {
    required double radius,
    required Color backgroundColor,
    required BorderSide side,
  }) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _signIn,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: backgroundColor,
        side: side,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: const Text('Crear cuenta nueva'),
    );
  }
}