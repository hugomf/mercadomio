import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:admin_console/services/admin_auth_service.dart';
import 'package:admin_console/services/oidc_flow.dart';
import 'package:admin_console/widgets/navigation_drawer.dart' as custom;
import 'package:admin_console/screens/catalog_management.dart';
import 'package:admin_console/screens/category_management.dart';
import 'package:admin_console/screens/order_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init('auth');
  AdminAuthService.instance.restore();
  runApp(const AdminConsoleApp());
}

class AdminConsoleApp extends StatelessWidget {
  const AdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Console',
      routes: {
        '/catalog': (context) => const CatalogManagementScreen(),
        '/categories': (context) => const CategoryManagementScreen(),
        '/login': (context) => const AdminLoginScreen(),
        '/auth/callback': (context) => const AdminCallbackScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AdminAuthGate(),
    );
  }
}

/// Shows the console only to authenticated users with the admin role.
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AdminAuthService.instance;
    if (!auth.isAuthenticated || !auth.isAdmin) {
      return const AdminLoginScreen();
    }
    return const AdminConsoleHome();
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AdminAuthService.instance.startLogin();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MercadoMío · Admin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acceso restringido al personal autorizado.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loading ? null : _signIn,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: const Text('Iniciar sesión'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminCallbackScreen extends StatefulWidget {
  const AdminCallbackScreen({super.key});

  @override
  State<AdminCallbackScreen> createState() => _AdminCallbackScreenState();
}

class _AdminCallbackScreenState extends State<AdminCallbackScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    final params = Uri.base.queryParameters;
    try {
      final ok = await AdminAuthService.instance.handleCallback(
        code: params['code'],
        state: params['state'],
        error: params['error'],
      );
      if (!mounted) return;
      if (ok && AdminAuthService.instance.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminConsoleHome()),
        );
      } else if (!ok) {
        setState(() => _error = 'No se pudo completar el inicio de sesión');
      } else {
        await AdminAuthService.instance.logout();
        setState(() =>
            _error = 'Tu cuenta no tiene el rol ${AdminAuthService.adminGroup}');
      }
    } on OidcException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
              const Text('Completando inicio de sesión...'),
            ] else ...[
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                ),
                child: const Text('Volver a iniciar sesión'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminConsoleHome extends StatefulWidget {
  const AdminConsoleHome({super.key});

  @override
  State<AdminConsoleHome> createState() => _AdminConsoleHomeState();
}

class _AdminConsoleHomeState extends State<AdminConsoleHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<void> _logout() async {
    await AdminAuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          // Persistent left sidebar on desktop; the menu button also opens it.
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: const Text('Order Management'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: _toggleTheme,
                  tooltip: 'Toggle dark mode',
                  focusNode: FocusNode(),
                  autofocus: true,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
            body: const Row(
              children: [
                custom.NavigationDrawer(),
                VerticalDivider(width: 1, thickness: 1),
                Expanded(child: OrderListScreen()),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Order Management'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              IconButton(
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleTheme,
                tooltip: 'Toggle dark mode',
                focusNode: FocusNode(),
                autofocus: true,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          drawer: const custom.NavigationDrawer(),
          body: const OrderListScreen(),
        );
      },
    );
  }
}
