import 'package:flutter/material.dart';
import 'package:admin_console/widgets/navigation_drawer.dart' as custom;

class CatalogManagementScreen extends StatefulWidget {
  const CatalogManagementScreen({super.key});

  @override
  State<CatalogManagementScreen> createState() => _CatalogManagementScreenState();
}

class _CatalogManagementScreenState extends State<CatalogManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog Management'),
      ),
      drawer: const custom.NavigationDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Catalog Management Content'),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement add product
              },
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}