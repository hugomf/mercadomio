import 'package:flutter/material.dart';
import '../widgets/admin/admin_nav.dart';
import '../widgets/admin/category_tree.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Side navigation
          const AdminNav(),
          // Main content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: const CategoryTree(),
            ),
          ),
        ],
      ),
    );
  }
}