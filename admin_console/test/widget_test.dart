import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_console/main.dart';

void main() {
  testWidgets('Admin console renders the orders dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AdminConsoleApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Order Management'), findsOneWidget);
  });

  testWidgets('Navigation drawer opens and shows menu items',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AdminConsoleApp());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Order Management'), findsWidgets);
    expect(find.text('Catalog Management'), findsOneWidget);
  });
}
