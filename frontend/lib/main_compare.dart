import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'theme.dart';
import 'services/cart_controller.dart';
import 'services/config_service.dart';
import 'services/category_service.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/order_service.dart';
import 'services/cart_service.dart';
import 'widgets/product_listing_widget.dart';
import 'widgets/cart_screen.dart';
import 'widgets/order_history_screen.dart';
import 'widgets/storefront_widget.dart';
import 'widgets/product_detail_screen.dart';
import 'widgets/footer.dart';
import 'widgets/checkout_screen.dart';
import 'models/order.dart';

// Temporary entry point for capturing screenshots of each screen at
// mobile/desktop widths. Usage:
//   flutter run -d chrome --target lib/main_compare.dart
//   then load http://localhost:3000/?screen=cart  (or storefront, listing,
//   detail, checkout, orders, login)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const CompareApp());
}

class CompareApp extends StatelessWidget {
  const CompareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final params = Uri.base.queryParameters;
    final screen = params['screen'] ?? 'storefront';
    final pid = params['pid'] ??
        '6a88bf04c0c2c2b5fea15828'; // a seeded product id
    final token = params['token'];

    // Put services so Get.find works inside the forced screen.
    Get.put(CartController());
    Get.put(ConfigService());
    Get.put(CategoryService());
    final authService = Get.put(AuthService());
    if (token != null && token.isNotEmpty) {
      authService.setTokenForCompare(token);
    }
    Get.put(ProductService());
    CartService(); // ensures singleton; cartId forced to seeded cart
    final apiUrl = const String.fromEnvironment('API_URL',
        defaultValue: 'http://localhost:8080');
    Get.put(OrderService(baseUrl: apiUrl));

    late final Widget page;
    switch (screen) {
      case 'storefront':
        page = Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                StorefrontWidget(),
                ProductListingWidget(),
              ],
            ),
          ),
          bottomNavigationBar: const Footer(),
        );
        break;
      case 'listing':
        page = Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                StorefrontWidget(isMobile: true),
                ProductListingWidget(),
              ],
            ),
          ),
        );
        break;
      case 'detail':
        page = ProductDetailScreen(productId: pid);
        break;
      case 'cart':
        page = const CartScreen();
        break;
      case 'checkout':
        page = CheckoutScreen(cartId: 'test-cart-001');
        break;
      case 'orders':
        // Inject mock order history so the screen renders with data even when
        // the backend auth flow (userbrew OIDC) is unavailable locally.
        final now = DateTime.now();
        final seed = OrderHistoryResponse(
          orders: [
            OrderResponse(
              id: '6834a1b2c3d4e5f600000001',
              userId: 'user-1',
              items: [
                OrderItem(
                    id: 'i1',
                    productId: 'p1',
                    quantity: 2,
                    price: 25.50,
                    productName: 'Tomates Saladet',
                    imageUrl: ''),
                OrderItem(
                    id: 'i2',
                    productId: 'p2',
                    quantity: 1,
                    price: 45.00,
                    productName: 'Aguacate Hass',
                    imageUrl: ''),
              ],
              total: 185.00,
              status: OrderStatus.shipped,
              createdAt: now,
              updatedAt: now,
            ),
            OrderResponse(
              id: '6829a1b2c3d4e5f600000002',
              userId: 'user-1',
              items: [
                OrderItem(
                    id: 'i3',
                    productId: 'p3',
                    quantity: 3,
                    price: 24.00,
                    productName: 'Leche Entera',
                    imageUrl: ''),
              ],
              total: 277.50,
              status: OrderStatus.completed,
              createdAt: now.subtract(const Duration(days: 9)),
              updatedAt: now.subtract(const Duration(days: 9)),
            ),
            OrderResponse(
              id: '6812a1b2c3d4e5f600000003',
              userId: 'user-1',
              items: [
                OrderItem(
                    id: 'i4',
                    productId: 'p4',
                    quantity: 2,
                    price: 115.00,
                    productName: 'Pan Blanco',
                    imageUrl: ''),
              ],
              total: 115.00,
              status: OrderStatus.cancelled,
              createdAt: now.subtract(const Duration(days: 16)),
              updatedAt: now.subtract(const Duration(days: 16)),
            ),
          ],
          total: 3,
          page: 1,
          limit: 20,
        );
        page = OrderHistoryScreen(
          orderService: Get.find<OrderService>(),
          seedOrders: seed,
        );
        break;
      case 'login':
        page = const SizedBox(); // placeholder; login not captured
        break;
      default:
        page = const SizedBox();
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mercadomio',
      theme: AppTheme.light,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      home: page,
    );
  }
}
