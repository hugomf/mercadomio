import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:frontend/services/auth_service.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/widgets/login_screen.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put(AuthService());
  });

  Future<void> pumpLogin(WidgetTester tester, {Size size = const Size(800, 600)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
    await tester.pump();
  }

  group('LoginScreen desktop (>=800px)', () {
    testWidgets('renders the brand header, card, CTAs and footer', (tester) async {
      await pumpLogin(tester);

      // Brand header (logo + wordmark) and the footer logo/wordmark.
      expect(find.text('Mercadomio'), findsNWidgets(2));

      // Card title + subtitle.
      expect(find.text('Iniciar sesión'), findsNWidgets(2)); // title + button
      expect(find.text('Ingresa a tu cuenta para continuar'), findsOneWidget);

      // Divider, secondary CTA and legal footer.
      expect(find.text('o'), findsOneWidget);
      expect(find.text('Crear cuenta nueva'), findsOneWidget);
      expect(find.text('Privacidad'), findsOneWidget);
    });
  });

  group('LoginScreen mobile (<800px)', () {
    testWidgets('renders the Hola header, card CTAs and footer', (tester) async {
      await pumpLogin(tester, size: const Size(400, 800));

      // Mobile mock: "¡Hola!" brand header.
      expect(find.text('¡Hola!'), findsOneWidget);
      expect(
        find.text('Inicia sesión para continuar comprando tus productos frescos.'),
        findsOneWidget,
      );

      // Cards: primary CTA, divider, secondary CTA and footer.
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      expect(find.text('Crear cuenta nueva'), findsOneWidget);
      expect(find.text('Privacidad'), findsOneWidget);
      expect(find.text('Mercadomio'), findsOneWidget); // footer only
    });
  });
}