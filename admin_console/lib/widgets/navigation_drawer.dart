import 'package:flutter/material.dart';
import 'package:admin_console/screens/catalog_management.dart';
import 'package:admin_console/screens/product_management.dart';

class NavigationDrawer extends StatefulWidget {
  const NavigationDrawer({super.key});

  @override
  State<NavigationDrawer> createState() => _NavigationDrawerState();
}

class _NavigationDrawerState extends State<NavigationDrawer> {
  bool _isCollapsed = false;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final drawerWidth = isMobile 
          ? constraints.maxWidth * 0.8
          : _isCollapsed ? 80.0 : 250.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: drawerWidth,
          child: Drawer(
            child: Column(
              children: [
                _buildHeader(context, constraints),
                const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                _buildQuickActionsSection(context),
                const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                _buildAdminSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BoxConstraints constraints) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: constraints.maxWidth < 600 ? 8 : 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(_isCollapsed ? Icons.menu : Icons.arrow_back),
            onPressed: _toggleCollapse,
            tooltip: _isCollapsed ? 'Expand' : 'Collapse',
            focusNode: FocusNode(),
            autofocus: true,
          ),
          if (!_isCollapsed)
            const Text(
              'Admin Console',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        _buildMenuItem(
          context,
          icon: Icons.dashboard,
          label: 'Dashboard',
          onTap: () {
            // TODO: Implement dashboard navigation
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.notifications,
          label: 'Alerts',
          onTap: () {
            // TODO: Implement alerts navigation
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Admin Section',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        _buildMenuItem(
          context,
          icon: Icons.list,
          label: 'Catalog Management',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CatalogManagementScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.category,
          label: 'Category Management',
          onTap: () {
            Navigator.pushNamed(context, '/categories');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.shopping_bag,
          label: 'Product Management',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductManagementScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.inventory,
          label: 'Inventory',
          onTap: () {
            // TODO: Implement inventory navigation
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.people,
          label: 'User Management',
          onTap: () {
            // TODO: Implement user management navigation
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.settings,
          label: 'Settings',
          onTap: () {
            // TODO: Implement settings navigation
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: _isCollapsed ? null : AnimatedOpacity(
        opacity: _isCollapsed ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Text(label),
      ),
      focusNode: FocusNode(),
      autofocus: true,
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Theme.of(context).colorScheme.primary.withAlpha(25),
      splashColor: Theme.of(context).colorScheme.primary.withAlpha(50),
    );
  }
}