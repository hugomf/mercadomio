import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';


class ProductSearchControls extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function() onClearSearch;
  final Function(String) onSortSelected;
  final Function(String) onViewModeChanged;
  final String currentViewMode;
  final RxString searchText;

  const ProductSearchControls({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortSelected,
    required this.onViewModeChanged,
    required this.currentViewMode,
    required this.searchText,
  });

  // Responsive design system
  double _getResponsiveValue(BuildContext context, 
      {required double mobile, required double tablet, required double desktop, double? fourK}) {
    if (ResponsiveBreakpoints.of(context).isMobile) return mobile;
    if (ResponsiveBreakpoints.of(context).isTablet) return tablet;
    if (ResponsiveBreakpoints.of(context).isDesktop) return desktop;
    return fourK ?? desktop;
  }

  double _getFontSize(BuildContext context, {required double base}) {
    return _getResponsiveValue(context,
      mobile: base * 0.9,
      tablet: base,
      desktop: base * 1.1,
      fourK: base * 1.2,
    );
  }

  double _getIconSize(BuildContext context, {required double base}) {
    return _getResponsiveValue(context,
      mobile: base * 0.9,
      tablet: base,
      desktop: base * 1.1,
      fourK: base * 1.2,
    );
  }

  double _getPadding(BuildContext context, {required double base}) {
    return _getResponsiveValue(context,
      mobile: base * 0.8,
      tablet: base,
      desktop: base * 1.2,
      fourK: base * 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = _getPadding(context, base: 16);
    final smallPadding = _getPadding(context, base: 8);
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop || ResponsiveBreakpoints.of(context).isTablet;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: smallPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search bar
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(fontSize: _getFontSize(context, base: isDesktop ? 16 : 14)),
                prefixIcon: Icon(Icons.search, size: _getIconSize(context, base: isDesktop ? 22 : 20)),
                suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      key: const Key('search_clear_button'),
                      icon: Icon(Icons.close, size: _getIconSize(context, base: isDesktop ? 20 : 18)),
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                    )
                  : SizedBox(width: _getPadding(context, base: 48)),
                contentPadding: EdgeInsets.symmetric(
                  vertical: _getPadding(context, base: isDesktop ? 14 : 12),
                  horizontal: _getPadding(context, base: 16),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_getPadding(context, base: 8)),
                ),
              ),
              style: TextStyle(fontSize: _getFontSize(context, base: isDesktop ? 16 : 14)),
            ),
          ),
          SizedBox(width: smallPadding),
          // Sorting button
          Container(
            height: _getPadding(context, base: isDesktop ? 48 : 44),
            width: isDesktop ? null : _getPadding(context, base: 48),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(_getPadding(context, base: 8)),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.sort, size: _getIconSize(context, base: isDesktop ? 22 : 20)),
              onSelected: onSortSelected,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'basePrice_asc',
                  child: Text(
                    'Price ↑ Low to High',
                    style: TextStyle(fontSize: _getFontSize(context, base: isDesktop ? 16 : 14)),
                  ),
                ),
                PopupMenuItem(
                  value: 'basePrice_desc',
                  child: Text(
                    'Price ↓ High to Low',
                    style: TextStyle(fontSize: _getFontSize(context, base: isDesktop ? 16 : 14)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: smallPadding),
          // View mode toggle
          Container(
            height: _getPadding(context, base: isDesktop ? 48 : 44),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(_getPadding(context, base: 8)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view,
                    size: _getIconSize(context, base: isDesktop ? 22 : 20),
                    color: currentViewMode == 'card'
                      ? Colors.deepPurple
                      : Colors.grey,
                  ),
                  onPressed: () => onViewModeChanged('card'),
                ),
                Container(
                  width: 1,
                  height: _getPadding(context, base: 20),
                  color: Colors.grey[300],
                ),
                IconButton(
                  icon: Icon(
                    Icons.list,
                    size: _getIconSize(context, base: isDesktop ? 22 : 20),
                    color: currentViewMode == 'list'
                      ? Colors.deepPurple
                      : Colors.grey,
                  ),
                  onPressed: () => onViewModeChanged('list'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}