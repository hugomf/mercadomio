import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/category.dart';
import '../services/category_service.dart';

/// Desktop-only storefront hero + category tiles shown above the product
/// listing on wide screens, matching the Stitch storefront design.
///
/// Tapping a category tile selects it through [CategoryService]; the product
/// listing below reacts automatically via the CategoryEventBus subscription
/// in [ProductListingWidget].
class StorefrontWidget extends StatefulWidget {
  const StorefrontWidget({super.key});

  @override
  State<StorefrontWidget> createState() => _StorefrontWidgetState();
}

class _StorefrontWidgetState extends State<StorefrontWidget> {
  final CategoryService _categoryService = Get.find<CategoryService>();

  @override
  void initState() {
    super.initState();
    // Ensure categories are loaded on first desktop render (mobile loads
    // them through CategorySelector). Selecting "All" publishes to the event
    // bus, which is harmless on startup.
    if (_categoryService.categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _categoryService.getCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(onSeeOffers: _categoryService.clearSelectedCategories),
        const SizedBox(height: 32),
        _buildSectionTitle(context, 'Categorías principales'),
        const SizedBox(height: 16),
        GetBuilder<CategoryService>(
          builder: (service) => _CategoryTiles(
            categories: service.categories,
            onCategoryTap: (category) =>
                service.addSelectedCategory(category.id, category.name),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Hero banner replicating the Stitch storefront hero: a primary-container
/// panel with gradient overlay, a promotional pill and a call-to-action.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onSeeOffers});

  /// Clears the current category filter so all offers are shown.
  final VoidCallback onSeeOffers;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Decorative gradient overlay for visual depth (kept asset-free).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.9),
                    colorScheme.primaryContainer.withValues(alpha: 0.7),
                    colorScheme.primaryContainer.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                // Never overflow the banner: scale the stacked content down
                // when the available space is tighter than its natural size.
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'OFERTA ESPECIAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '20% de descuento en\nFrutas y Verduras',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onSeeOffers,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      label: const Text('Ver ofertas'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of circular category tiles. Hover inverts the tile
/// background/text to highlight interactivity, mirroring the Stitch design.
class _CategoryTiles extends StatefulWidget {
  const _CategoryTiles({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final void Function(Category category) onCategoryTap;

  @override
  State<_CategoryTiles> createState() => _CategoryTilesState();
}

class _CategoryTilesState extends State<_CategoryTiles> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final visible = widget.categories.take(7).toList();

    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 24),
          _buildTile(context, visible[i], i),
        ],
      ],
    );
  }

  Widget _buildTile(BuildContext context, Category category, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final hovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Tooltip(
        message: category.name,
        child: InkWell(
          onTap: () => widget.onCategoryTap(category),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 112,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: hovered
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hovered
                          ? colorScheme.secondaryContainer
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Icon(
                    _iconFor(category.name),
                    size: 28,
                    color: hovered
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: hovered
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Maps each category name to a representative Material icon, matching the
  /// Stitch design's icon choices; falls back to a generic icon.
  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruta') || lower.contains('verd')) {
      return Icons.eco;
    }
    if (lower.contains('carne')) {
      return Icons.set_meal;
    }
    if (lower.contains('pan')) {
      return Icons.bakery_dining;
    }
    if (lower.contains('lact') || lower.contains('huevo') || lower.contains('leche')) {
      return Icons.egg_alt;
    }
    if (lower.contains('abarro')) {
      return Icons.kitchen;
    }
    if (lower.contains('bebida')) {
      return Icons.local_drink;
    }
    if (lower.contains('limpi')) {
      return Icons.cleaning_services;
    }
    return Icons.category;
  }
}