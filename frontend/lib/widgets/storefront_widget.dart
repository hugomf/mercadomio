import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import 'cart_icon.dart';

/// Storefront hero, category tiles and offers section.
///
/// On desktop this renders the full desktop layout with hero, category grid,
/// and offers product cards matching the Stitch desktop mock.
/// On mobile the caller wraps the storefront inside a [CustomScrollView];
/// the sticky header (location chip + search + cart) is provided by
/// [_MobileStorefrontHeader] via [StorefrontHeaderDelegate].
///
/// Tapping a category tile selects it through [CategoryService]; the product
/// listing below reacts automatically via the CategoryEventBus subscription
/// in [ProductListingWidget].
class StorefrontWidget extends StatefulWidget {
  const StorefrontWidget({
    super.key,
    this.isMobile = false,
    this.onCategoryTap,
    this.onSeeOffers,
    this.searchController,
    this.onSearchChanged,
  });

  /// Whether to render the compact mobile variant (smaller hero, tighter
  /// spacing, mobile-adapted category tile sizes).
  final bool isMobile;

  /// Called when a category is tapped (desktop grid) or for mobile horizontal scroll.
  final void Function(Category category)? onCategoryTap;

  /// Called when "Ver ofertas" is pressed.
  final VoidCallback? onSeeOffers;

  /// Search controller for desktop search bar.
  final TextEditingController? searchController;

  /// Called when search text changes (desktop).
  final ValueChanged<String>? onSearchChanged;

  /// Hero background photo of fresh vegetables (matches the Stitch mock's
  /// produce imagery). Uses Unsplash's stable CDN URL.
  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1547592854-'
      'b9e4a38f6fef?auto=format&fit=crop&w=1200&q=60';

  /// Maps each category name to a representative Material icon, matching the
  /// Stitch design's icon choices; falls back to a generic icon.
  static IconData _iconFor(String name) {
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
    if (lower.contains('lact') ||
        lower.contains('huevo') ||
        lower.contains('leche')) {
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

  @override
  State<StorefrontWidget> createState() => _StorefrontWidgetState();
}

class _StorefrontWidgetState extends State<StorefrontWidget> {
  final CategoryService _categoryService = Get.find<CategoryService>();

  @override
  void initState() {
    super.initState();
    // Ensure categories are loaded on first render.
    if (_categoryService.categories.isEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _categoryService.getCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      // Mobile: the caller places this inside a CustomScrollView that already
      // has a pinned [SliverPersistentHeader] with [_MobileStorefrontHeader].
      return _buildMobileContent(context);
    }

    // Desktop/tablet: full desktop layout with hero, category grid, and offers section.
    return _buildDesktopLayout(context);
  }

  Widget _buildMobileContent(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(
          isMobile: true,
          onSeeOffers:
              widget.onSeeOffers ?? _categoryService.clearSelectedCategories,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'Categorías principales'),
        const SizedBox(height: 16),
        GetBuilder<CategoryService>(
          builder: (service) => _CategoryTiles(
            categories: service.categories,
            onCategoryTap: widget.onCategoryTap ??
                (category) =>
                    service.addSelectedCategory(category.id, category.name),
            isMobile: true,
          ),
        ),
        const SizedBox(height: 24),
        _buildOffersHeader(context),
        const SizedBox(height: 16),
      ],
    );

    return content;
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final categoryService = Get.find<CategoryService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Banner (desktop)
        _HeroBanner(
          isMobile: false,
          onSeeOffers:
              widget.onSeeOffers ?? categoryService.clearSelectedCategories,
        ),
        const SizedBox(height: 32),
        // Categories Section (desktop grid)
        _buildSectionTitle(context, 'Categorías principales'),
        const SizedBox(height: 16),
        GetBuilder<CategoryService>(
          builder: (service) => _CategoryGrid(
            categories: service.categories,
            onCategoryTap: widget.onCategoryTap ??
                (category) =>
                    service.addSelectedCategory(category.id, category.name),
          ),
        ),
        const SizedBox(height: 40),
        // Offers Section (desktop grid of product cards)
        _buildOffersHeader(context),
        const SizedBox(height: 16),
        _OffersGrid(isMobile: false),
      ],
    );
  }

  /// \"Ofertas de la semana\" section header matching the Stitch design:
  /// a fire icon, the title and a \"Ver todas\" action.
  Widget _buildOffersHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.local_fire_department, color: colorScheme.tertiary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Ofertas de la semana',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.isMobile ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _categoryService.clearSelectedCategories,
          child: const Text('Ver todas'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: widget.isMobile ? 20 : 22,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Delegate that paints [_MobileStorefrontHeader] as a pinned, sticky
/// SliverPersistentHeader so it stays visible while the page scrolls.
class StorefrontHeaderDelegate extends SliverPersistentHeaderDelegate {
  StorefrontHeaderDelegate({
    required this.height,
    required this.searchController,
    required this.onSearchChanged,
  });

  final double height;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: _MobileStorefrontHeader(
        searchController: searchController,
        onSearchChanged: onSearchChanged,
      ),
    );
  }

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(covariant StorefrontHeaderDelegate oldDelegate) =>
      oldDelegate.height != height;
}

/// Sticky mobile TopAppBar: location chip + search bar + cart icon,
/// matching the Stitch mobile mock. This is rendered as the child of
/// [StorefrontHeaderDelegate] so it stays pinned while the page scrolls.
class _MobileStorefrontHeader extends StatelessWidget {
  const _MobileStorefrontHeader({
    required this.searchController,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Location chip + cart icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location chip
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enviar a:',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Polanco, CDMX',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Cart icon with badge
              const CartIcon(),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Search bar
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar productos',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero banner replicating the Stitch storefront hero: a primary-container
/// panel with gradient overlay, a promotional pill and a call-to-action.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.onSeeOffers,
    this.isMobile = false,
  });

  /// Clears the current category filter so all offers are shown.
  final VoidCallback onSeeOffers;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final height = isMobile ? 200.0 : 400.0;
    final hPadding = isMobile ? 24.0 : 40.0;
    final vPadding = isMobile ? 20.0 : 40.0;

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hero background photo, softly blending into the primary container
          // (matches the mock's `opacity-80 mix-blend-overlay` image layer).
          Positioned.fill(
            child: Opacity(
              opacity: 0.55,
              child: CachedNetworkImage(
                imageUrl: StorefrontWidget._heroImageUrl,
                fit: BoxFit.cover,
                color: colorScheme.primaryContainer,
                colorBlendMode: BlendMode.overlay,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
                placeholder: (_, __) =>
                    const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
          // Gradient overlay fading out towards the right so the text stays
          // readable while the image peeks through on the far side.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.75),
                    colorScheme.primaryContainer.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                          fontSize: isMobile ? 26 : 46,
                          height: 1.1,
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
                            horizontal: 24,
                            vertical: 14,
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
    this.isMobile = false,
  });

  final List<Category> categories;
  final void Function(Category category) onCategoryTap;
  final bool isMobile;

  @override
  State<_CategoryTiles> createState() => _CategoryTilesState();
}

class _CategoryTilesState extends State<_CategoryTiles> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final visible = widget.categories.take(7).toList();
    final tileWidth = widget.isMobile ? 92.0 : 112.0;
    final circleSize = widget.isMobile ? 56.0 : 64.0;
    final iconSize = widget.isMobile ? 24.0 : 28.0;
    final gap = widget.isMobile ? 16.0 : 24.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _buildTile(context, visible[i], i, tileWidth, circleSize, iconSize),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, Category category, int index,
      double tileWidth, double circleSize, double iconSize) {
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
            width: tileWidth,
            child: Column(
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
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
                    StorefrontWidget._iconFor(category.name),
                    size: iconSize,
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
                    fontFamily: 'Public Sans', // label font per Stitch DS
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop category grid matching Stitch desktop mock (7 items, circular tiles
/// with hover that inverts the tile background like the mock's
/// `group-hover:bg-secondary-container` behaviour).
class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final void Function(Category category) onCategoryTap;

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = widget.categories.take(7).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final category = visible[index];
        final hovered = _hoveredIndex == index;
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: Tooltip(
            message: category.name,
            child: InkWell(
              onTap: () => widget.onCategoryTap(category),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
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
                      StorefrontWidget._iconFor(category.name),
                      size: 32,
                      color: hovered
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      color: hovered
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Desktop offers grid matching Stitch desktop mock (4 product cards with discount badges).
class _OffersGrid extends StatelessWidget {
  const _OffersGrid({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    // Sample offer data matching Stitch mock
    final offers = [
      {
        'discount': '-28%',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCRXSVZ1KMXPH3RNNT6GQrySWnmBJMljC5Zy9XBYrYmEIqJ-njB9t_gl6fSYEn5N8-S03ik_Z4kmWDoA9GjjGr129cZRjOrJjWj3-KrAbo9G-nEpt2VfSJv5CCzy--zGnCMbyw_JpFb7n5qKoG_S9pTLCCIeINMAA0qxNiRm0gcqQtAJ2-Eb7gnhuQMoaIknEivcAkfOi5ZsBEDz8Vovf8HrTtNsenixFlnNHGW4VZzPPN9UkCBH4KZYgqwotbhEI0VvUBxk9xIWtU',
        'category': 'Verduras',
        'name': 'Tomate Cherry Orgánico Empaque 500g',
        'originalPrice': 45.00,
        'salePrice': 32.40,
      },
      {
        'discount': '-15%',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC3Pw5zrntuHkYQh5IlzV-kGrv61s4smovAxcdCBTHEDZUeMi_yXpT705HaYajdd0H8ZQGJZi7a4N0jvNY2ufSdzfZ8_p3DMU8Zp1O-RX5O39MzLTC4vals7zSHzbGahCTJyVni52TdWOa3pZsWvzEecNLmkEaKGz5Bo5ELlE8zikVmnm__wK0cQ1GtmpRMvCR7R_DK9nnI6mkSZLD5s6g6YEF6WC21hAgGdxLU9I59GQAQuE7geJY3cN4rq6eIGKoCOQlsvJoIsVA',
        'category': 'Verduras',
        'name': 'Espárragos Verdes Frescos Manojo',
        'originalPrice': 89.90,
        'salePrice': 76.41,
      },
      {
        'discount': '-20%',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuA9QLhhIIRB7gu8FZZf_Kilw7Q8bWEDNDq5RCowUNm5R9Qh1q04-CVuYgrf-AQA1ajvYqcYaGXPszl557xz6PfbuuDqbNqkwxjFLCLRhWSmstaXmRYbOjygyCfzlScDWpaPLoREsIdl_q8UC76hWrEorpP2cI1vee3Ekka7ob2O01QSR1Yr5h3ZZ7VBHfTkKey-NVpUtmPgOz9nPoR0bIsb_iKTsVPxsJyklNkIU1hNuevMubqJNCM6ZvLO0p6TTe9yWXonEtYf9YU',
        'category': 'Frutas',
        'name': 'Plátano Tabasco Fresco 1kg',
        'originalPrice': 25.50,
        'salePrice': 20.40,
      },
      {
        'discount': '-10%',
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuASnYyNeuRggaxU_PDJ1yRXX1DOH8aA9hjczGKcmFhqSE9Y47cZzodf8xAQYtrhARySsI4FKqjtkVhYHl0cCq6YmabXhZ7DfdjuJUluzLQes4_jluPxUeNRTQY0_NHYOux-STSF-tbelzDH7p6AjyT_7xvNftCvYgdxl6huUWCuShv6u_akojm0OR35rUCJKSrGxW7_GkcV38iSR2Gp_YFGoe6wWVlpPCyv0GdUCVaN7MRJDU4oiZwbfwoLlY-0I6C7Hgot4iefHBc',
        'category': 'Lácteos y Huevo',
        'name': 'Huevo Blanco San Juan 18 pzas',
        'originalPrice': 54.00,
        'salePrice': 48.60,
      },
    ];

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.52,
          ),
          itemCount: offers.length,
          itemBuilder: (context, index) =>
              _OfferCard(offer: offers[index], isCompact: true),
        ),
      );
    }

    // Desktop: responsive columns (2 until wide enough for 4, mirroring the
    // mock's `sm:grid-cols-2 lg:grid-cols-4`), with a card aspect generous
    // enough that the square image + content never overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 4 : 2;
        final aspect = columns == 4 ? 0.68 : 0.62;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: aspect,
          ),
          itemCount: offers.length,
          itemBuilder: (context, index) => _OfferCard(offer: offers[index]),
        );
      },
    );
  }
}

/// Offer product card matching the Stitch desktop mock: square image with a
/// discount badge, category label, name, prices and a circular add button.
/// Hover raises the card shadow and zooms the image (`hover:shadow-md`,
/// `group-hover:scale-105` in the mock).
class _OfferCard extends StatefulWidget {
  const _OfferCard({required this.offer, this.isCompact = false});

  final Map<String, dynamic> offer;

  /// Renders the tighter mobile variant (smaller paddings/sizes).
  final bool isCompact;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final offer = widget.offer;
    final discount = offer['discount'] as String;
    final image = offer['image'] as String;
    final category = offer['category'] as String;
    final name = offer['name'] as String;
    final originalPrice = offer['originalPrice'] as double;
    final salePrice = offer['salePrice'] as double;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: _hovered ? 0.10 : 0.04,
              ),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AnimatedScale(
                        scale: _hovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: Image.network(
                          image,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      discount,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onError,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                        fontFamily: 'Public Sans',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '\$${salePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: widget.isCompact ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        // Add to cart button (circular)
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(17),
                          child: Container(
                            width: widget.isCompact ? 30 : 34,
                            height: widget.isCompact ? 30 : 34,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              size: widget.isCompact ? 16 : 18,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
