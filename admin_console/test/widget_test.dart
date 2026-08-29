import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_console/main.dart';

void main() {
  testWidgets('Admin console shows the login gate when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AdminConsoleApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('MercadoMío · Admin'), findsOneWidget);
    expect(find.text('Order Management'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('Admin console renders the orders dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminConsoleHome()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Order Management'), findsWidgets);
  });

  testWidgets('Navigation drawer opens and shows menu items',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminConsoleHome()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Order Management'), findsWidgets);
    expect(find.text('Catalog Management'), findsWidgets);
  });
}