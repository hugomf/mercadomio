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

  // Desktop nav indices (single source of truth): 0 Inicio, 1 Categorías,
  // 2 Carrito, 3 Pedidos, 4 Perfil. The mobile bottom bar only exposes
  // Inicio/Carrito/Pedidos, mapping those to desktop indices via
  // [_mobileTabToIndex].
  static const List<int> _mobileTabToIndex = [0, 2, 3];

  // Derive which mobile bottom-bar tab corresponds to the current selection,
  // clamping desktop-only indices (Categorías, Perfil) to Inicio so the bar
  // never builds with an out-of-range currentIndex.
  int _bottomNavIndex() {
    switch (_selectedIndex) {
      case 2:
        return 1; // Carrito
      case 3:
        return 2; // Pedidos
      default:
        return 0; // Inicio (also Categorías and Perfil)
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop ? _buildDesktopHeader() : _buildMobileAppBar(),
      body: isDesktop
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: _buildContent(),
              ),
            )
          : _buildContent(),
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
              currentIndex: _bottomNavIndex(),
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              onTap: (index) => _onItemTapped(_mobileTabToIndex[index]),
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 2:
        return const CartScreen();
      case 3:
        return _buildOrdersScreen();
      case 4:
        return _ProfileView(
          onOrdersTap: () => _onItemTapped(3),
        );
      default:
        return const HomeScreen();
    }
  }

  // Mobile top bar: brand title, search shortcut, cart and account actions.
  AppBar _buildMobileAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
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
                _onProfileItemTapped();
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
    );
  }

  // Desktop top navigation bar matching the Stitch mock's TopNav: a first row
  // with brand, zone pill, search field and cart/account actions, and a second
  // row with the section links. Replaces the legacy left sidebar (no mock
  // uses a sidebar).
  PreferredSizeWidget _buildDesktopHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return PreferredSize(
      preferredSize: const Size.fromHeight(112),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag,
                          size: 28, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Mercadomio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(width: 190, child: _DesktopLocationChip()),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _onItemTapped(0),
                            decoration: InputDecoration(
                              hintText: 'Buscar productos, marcas y más...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLowest,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CartIcon(),
                      AuthOptional(
                        authenticatedChild: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'logout') {
                              Get.find<AuthService>().logout();
                            } else if (value == 'profile') {
                              _onProfileItemTapped();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Text('Perfil'),
                            ),
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Text('Cerrar sesión'),
                            ),
                          ],
                          child: Icon(
                            Icons.account_circle,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        unauthenticatedChild: IconButton(
                          icon: Icon(
                            Icons.account_circle,
                            color: colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          tooltip: 'Iniciar sesión',
                          onPressed: () => Get.to(
                            () => const AuthGuard(child: SizedBox()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildNavLinks(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Section links shown in the second row of the desktop header (Inicio,
  // Categorías, Pedidos, Perfil), matching the mock's active underline style.
  Widget _buildNavLinks() {
    final colorScheme = Theme.of(context).colorScheme;
    const links = <(int, String)>[
      (0, 'Inicio'),
      (1, 'Categorías'),
      (3, 'Pedidos'),
      (4, 'Perfil'),
    ];
    return Row(
      children: links.map((link) {
        final (index, label) = link;
        final selected = _selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 28),
          child: InkWell(
            onTap: () {
              if (index == 4) {
                _onProfileItemTapped();
              } else {
                _onItemTapped(index);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: selected
                    ? Border(
                        bottom: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
      // flexible product listing. The storefront never starves the listing:
      // it is capped at half the panel height AND leaves at least 320px of
      // vertical space for the listing (scrolling internally if needed).
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
                      maxHeight: (constraints.maxHeight - 320)
                          .clamp(0.0, constraints.maxHeight * 0.5),
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
