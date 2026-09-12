import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/order_service.dart';

void main() {
  group('OrderService.getOrderHistory filter', () {
    test('builds URI with status bucket param', () {
      final svc = OrderService(baseUrl: 'http://localhost:8080');
      // We test the URI building via a helper we will add.
      // Until the helper exists, this test fails to compile (RED).
      final uri = svc.buildOrderHistoryUri(page: 1, limit: 20, status: 'En camino');
      expect(uri.queryParameters['status'], 'En camino');
      expect(uri.queryParameters['page'], '1');
    });

    test('Todos still includes status (explicit)', () {
      final svc = OrderService(baseUrl: 'http://localhost:8080');
      final uri = svc.buildOrderHistoryUri(page: 2, limit: 10, status: 'Todos');
      expect(uri.queryParameters['status'], 'Todos');
    });

    test('unknown status defaults to Todos handling in backend', () {
      final svc = OrderService(baseUrl: 'http://localhost:8080');
      final uri = svc.buildOrderHistoryUri(page: 1, limit: 20, status: 'unknown');
      expect(uri.toString(), contains('status=unknown'));
    });
  });
}
