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
import 'widgets/product_listing_widget.dart';
import 'widgets/cart_screen.dart';
import 'widgets/cart_icon.dart';
import 'widgets/auth_guard.dart';
import 'widgets/order_history_screen.dart';
import 'widgets/storefront_widget.dart';
import 'services/order_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mercadomio',
      theme: AppTheme.light,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      home: const MainScreen(),
      getPages: [
      ],
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  OrderService? _orderService;

  @override
  void initState() {
    super.initState();
    Get.put(CartController());
    Get.put(ConfigService());
    Get.put(CategoryService());
    Get.put(AuthService());
    Get.put(ProductService());
    _initOrderService();
  }

  Future<void> _initOrderService() async {
    final configService = Get.find<ConfigService>();
    final authService = Get.find<AuthService>();
    final apiUrl = await configService.getApiUrl();
    if (!mounted) return;
    setState(() {
      _orderService = OrderService(
        baseUrl: apiUrl,
        authToken: authService.token,
      );
    });
  }

  int _selectedIndex = 0;

  Widget _buildOrdersScreen() {
    final orderService = _orderService;
    if (orderService == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return OrderHistoryScreen(orderService: orderService);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag,
                  size: isSmallScreen ? 24 : 28,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mercadomio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 19 : 21,
                    letterSpacing: 0.2,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            onPressed: () {
              _onItemTapped(0);
            },
          ),
          const CartIcon(),
          const SizedBox(width: 4),
          // User profile/logout
          AuthOptional(
            authenticatedChild: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  Get.find<AuthService>().logout();
                } else if (value == 'profile') {
                  // TODO: Show profile dialog
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
              child: Obx(() {
                final user = Get.find<AuthService>().currentUser;
                return Row(
                  children: [
                    if (user != null) ...[
                      Text(
                        user.name.split(' ').first,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      Icons.account_circle,
                      color: colorScheme.primary,
                    ),
                  ],
                );
              }),
            ),
            unauthenticatedChild: TextButton(
              onPressed: () => Get.to(() => const AuthGuard(child: SizedBox())),
              child: const Text('Iniciar sesión'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopSidebar(),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildDesktopContent()),
              ],
            )
          : _buildMobileContent(),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              backgroundColor: colorScheme.surfaceContainer,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Carrito',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Pedidos',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              onTap: _onItemTapped,
            ),
    );
  }

  Widget _buildMobileContent() {
    switch (_selectedIndex) {
      case 1:
        return const CartScreen();
      case 2:
        return _buildOrdersScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildDesktopContent() {
    switch (_selectedIndex) {
      case 1:
        return const CartScreen();
      case 2:
        return _buildOrdersScreen();
      case 4:
        return _ProfileView(
          onOrdersTap: () => _onItemTapped(2),
        );
      default:
        return const HomeScreen();
    }
  }

  Widget _buildDesktopSidebar() {
    final colorScheme = Theme.of(context).colorScheme;
    final navItems = <_DesktopNavItem>[
      _DesktopNavItem(
        icon: Icons.home_outlined,
        iconSelected: Icons.home,
        label: 'Inicio',
      ),
      _DesktopNavItem(
        icon: Icons.category_outlined,
        iconSelected: Icons.category,
        label: 'Categorías',
      ),
      _DesktopNavItem(
        icon: Icons.shopping_cart_outlined,
        iconSelected: Icons.shopping_cart,
        label: 'Carrito',
      ),
      _DesktopNavItem(
        icon: Icons.receipt_long_outlined,
        iconSelected: Icons.receipt_long,
        label: 'Pedidos',
      ),
      _DesktopNavItem(
        icon: Icons.person_outline,
        iconSelected: Icons.person,
        label: 'Perfil',
      ),
    ];

    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Icon(Icons.shopping_bag, size: 24, color: colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Mercadomio',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _DesktopLocationChip(),
          ),
          const SizedBox(height: 16),
          ...navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selected = _selectedIndex == index;
            final isProfile = item.label == 'Perfil';
            final isProfileActive = isProfile &&
                (Get.find<AuthService>().isAuthenticated ||
                    _selectedIndex == 4);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: selected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (isProfile) {
                      _onProfileItemTapped();
                    } else {
                      _onItemTapped(index);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? item.iconSelected
                              : item.icon,
                          size: 22,
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : isProfileActive
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w500,
                              color: selected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.support_agent,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ayuda y soporte',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onProfileItemTapped() {
    final authService = Get.find<AuthService>();
    if (authService.isAuthenticated) {
      setState(() => _selectedIndex = 4);
    } else {
      Get.to(() => const AuthGuard(child: SizedBox()));
    }
  }
}

class _DesktopNavItem {
  final IconData icon;
  final IconData iconSelected;
  final String label;

  const _DesktopNavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
  });
}

class _DesktopLocationChip extends StatefulWidget {
  @override
  State<_DesktopLocationChip> createState() => _DesktopLocationChipState();
}

class _DesktopLocationChipState extends State<_DesktopLocationChip> {
  String _zone = 'Polanco, CDMX';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final zone = await _pickZone();
        if (zone != null && mounted) {
          setState(() => _zone = zone);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enviar a',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _zone,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more,
                size: 18, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickZone() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final zones = [
          'Polanco, CDMX',
          'Roma Norte, CDMX',
          'Condesa, CDMX',
          'Chapultepec, CDMX',
        ];
        return SimpleDialog(
          title: const Text('Elige tu zona'),
          children: zones.map((zone) {
            return SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(zone),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(zone),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  final VoidCallback onOrdersTap;

  const _ProfileView({required this.onOrdersTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authService = Get.find<AuthService>();
    final user = authService.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Invitado',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Inicia sesión para sincronizar tu cuenta',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.location_on_outlined,
                          color: colorScheme.primary),
                      title: const Text('Mis direcciones'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.snackbar(
                        'Próximamente',
                        'La gestión de domicilios estará disponible pronto',
                        backgroundColor: colorScheme.tertiary,
                        colorText: colorScheme.onTertiary,
                        margin: const EdgeInsets.all(20),
                        borderRadius: 8,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.payment_outlined,
                          color: colorScheme.primary),
                      title: const Text('Métodos de pago'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.snackbar(
                        'Próximamente',
                        'La gestión de métodos de pago estará disponible pronto',
                        backgroundColor: colorScheme.tertiary,
                        colorText: colorScheme.onTertiary,
                        margin: const EdgeInsets.all(20),
                        borderRadius: 8,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.receipt_long_outlined,
                          color: colorScheme.primary),
                      title: const Text('Mis pedidos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onOrdersTap,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.shopping_bag_outlined,
                          color: colorScheme.primary),
                      title: const Text('Lista de deseos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.snackbar(
                        'Inicia sesión',
                        'Agrega artículos a tu lista de deseos desde cada producto',
                        backgroundColor: colorScheme.tertiary,
                        colorText: colorScheme.onTertiary,
                        margin: const EdgeInsets.all(20),
                        borderRadius: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (user != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    await authService.logout();
                    if (context.mounted) {
                      Get.snackbar(
                        'Sesión cerrada',
                        'Tu sesión se cerró correctamente',
                        backgroundColor: colorScheme.primary,
                        colorText: colorScheme.onPrimary,
                        margin: const EdgeInsets.all(20),
                        borderRadius: 8,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () =>
                      Get.to(() => const AuthGuard(child: SizedBox())),
                  icon: const Icon(Icons.login),
                  label: const Text('Iniciar sesión'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      // Mobile layout
      return Column(
        children: [
          const Expanded(
            child: ProductListingWidget(),
          ),
        ],
      );
    } else {
      // Desktop/tablet layout: storefront hero + category tiles above the
      // flexible product listing. The storefront is capped at half the panel
      // height (scrolling internally if needed) so it never starves the
      // listing on short windows.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.5,
                    ),
                    child: const SingleChildScrollView(
                      child: StorefrontWidget(),
                    ),
                  ),
                  const Expanded(
                    child: ProductListingWidget(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}
