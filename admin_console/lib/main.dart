import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:admin_console/widgets/navigation_drawer.dart' as custom;
import 'package:admin_console/screens/catalog_management.dart';
import 'package:admin_console/screens/category_management.dart';
import 'package:admin_console/screens/product_management.dart';
import 'package:admin_console/services/product_provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const AdminConsoleApp());
}

class AdminConsoleApp extends StatelessWidget {
  const AdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'Admin Console',
        routes: {
          '/catalog': (context) => const CatalogManagementScreen(),
          '/categories': (context) => const CategoryManagementScreen(),
          '/products': (context) => const ProductManagementScreen(),
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
        home: const AdminConsoleHome(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Admin Console'),
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
        ],
      ),
      drawer: const custom.NavigationDrawer(),
      body: const Center(
        child: Text('Main Content Area'),
      ),
    );
  }
}
