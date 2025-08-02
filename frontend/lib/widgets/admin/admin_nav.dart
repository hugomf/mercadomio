import 'package:flutter/material.dart';

class AdminNav extends StatelessWidget {
  const AdminNav({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: 0,
      labelType: NavigationRailLabelType.selected,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.category),
          label: Text('Categories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_bag),
          label: Text('Products'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      onDestinationSelected: (index) {
        // TODO: Handle navigation
      },
    );
  }
}