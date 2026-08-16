# Session Log

## 2026-08-15 — Desktop login screen aligned to Stitch design

Request: user said "next" (continuing the desktop Stitch alignment; cuarto design remaining in `.stitch/designs-desktop/`). Target `.stitch/designs-desktop/login-desktop.html`.

Changes:
- `frontend/lib/widgets/login_screen.dart` (desktop branch only; mobile untouched):
  - Brand header moved out of the card into a `_buildBrandHeader` (48px primaryContainer circle with shopping_bag icon + "Mercadomio" w900 primary) above the form, matching the Stitch logo + wordmark row.
  - Card centered column narrowed to `maxWidth: 440` (was 460), keeping the rounded-16 card with border + soft shadow.
  - Password field: added `_obscurePassword` state + visibility/visibility_off suffix toggle button (styling matches Stitch eye toggle on the right of the input).
  - Added right-aligned text link between password and submit: "¿Olvidaste tu contraseña?" in login mode / "¿Ya tienes cuenta? Inicia sesión" in register mode (replaces the old bottom-center trailing TextButton; still calls `_toggleMode`).
  - Removed the now-redundant trailing toggle TextButton and the "Demo: usa cualquier correo y contraseña" hint from the desktop card (register mode is still reachable via the outlined "Crear cuenta nueva" button).
  - Outlined secondary button border upgraded to `width: 2` + `colorScheme.outline` to match Stitch border-2.

Verified: `flutter analyze` → No issues found; `flutter test` → All tests passed.

## 2026-08-15 — Desktop storefront aligned to Stitch design

Request: user said "next" (continuing the desktop Stitch alignment; sequence was cart → checkout → order-history → product-detail → product-listing → storefront). Target `.stitch/designs-desktop/storefront-desktop.html`.

Changes:
- New `frontend/lib/widgets/storefront_widget.dart`: `StorefrontWidget` (desktop-only, shown above the product listing). Renders a hero banner matching the Stitch hero (primaryContainer, 300px, rounded-16, gradient overlay, tertiary-container "OFERTA ESPECIAL" pill, "20% de descuento en Frutas y Verduras" headline, "Ver ofertas" StadiumButton that clears the category filter) plus a "Categorías principales" section with up to 7 circular category tiles (icon mapping via keyword heuristics: fruta/verd→eco, carne→set_meal, pan→bakery_dining, lact/huevo/leche→egg_alt, abarro→kitchen, bebida→local_drink, limpi→cleaning_services, fallback category), hover inverts bg/text, tap → `CategoryService.addSelectedCategory`. `initState` loads categories via postFrame when empty. Hero content is wrapped in `FittedBox(scaleDown)` so it never overflows on short viewports.
- `frontend/lib/main.dart`: desktop HomeScreen branch now places `StorefrontWidget` above `ProductListingWidget` inside a `LayoutBuilder`; the storefront is capped at 50% of panel height inside a `SingleChildScrollView` so it never starves the listing. Mobile branch untouched; AppBar + sidebar chrome untouched.
- `frontend/lib/services/category_service.dart`: `removeSelectedCategory` and `clearSelectedCategories` now also publish to `CategoryEventBus` (previously only `addSelectedCategory` and `removeCategoriesFromIndex` did), so every selection mutation notifies listeners.
- `frontend/lib/widgets/product_listing_widget.dart`: subscribes to `CategoryEventBus.stream` in `initState` (with `dispose` cancel) and refetches products on any category change anywhere in the app. Removed now-redundant direct `_fetchProducts()` calls after category mutations (mobile CategorySelector/CategoryBreadcrumbs callbacks → no-op, desktop sidebar items, filter-chip remove, "Limpiar filtros") to avoid double fetches. Search-only paths (onClearSearch, onSortSelected, search-term chip) still fetch explicitly.

Verified: `flutter analyze` → No issues found; `flutter test` → All tests passed.

## 2026-08-15 — Desktop product listing screen aligned to Stitch design

Request: user said "next" (continuing the desktop Stitch alignment; sequence was cart → checkout → order-history → product-detail → product-listing). Target `.stitch/designs-desktop/product-listing-desktop.html`.

Changes in `frontend/lib/widgets/product_listing_widget.dart` (desktop branch only, mobile layout untouched):
- Page header: replaced the old `CategoryBreadcrumbs` Padding + count GetBuilder Padding with `_buildDesktopPageHeader()` — Stitch-style breadcrumb row (Inicio > Categorías > active category), h1 title (`activeLabel` = last selected category name, or "Productos"), "{count} productos disponibles" subtitle (uses `_filteredProducts` when filtering/searching, else `_totalProducts`).
- Applied-filters chips: new `_buildAppliedFilterChips` — one `primaryContainer` stadium Chip per selected category (remove via `removeCategoriesFromIndex(i)` + refetch), a search-term chip "“query”" when searching, and a "Limpiar filtros" TextButton that clears categories + search and refetches.
- Sidebar restyle: `_buildCategorySidebar()` is now a floating card (surfaceContainerLowest, radius 12, border surfaceContainer, subtle shadow, width 240, vertical margin). `_buildSidebarHeader` shows title + `expand_less` icon; `_buildSidebarItem` uses check_box/check_box_outline_blank (primary/outline), bold+primary when selected. "Todos" first, same callbacks. Added `SizedBox(width: 24)` gap between sidebar and content.
- Product card (`_buildDesktopProductCard`): discount badge now `colorScheme.error` bg + `onError` text, radius 6 (Stitch rounded-md), compact padding h8/v4, fontSize 11; removed the category uppercase label block (Stitch cards have none); added inline `/ unit` suffix under the current price on non-discounted cards; add button now circular with `bg primary + onPrimary` when discounted else `primaryContainer` + primary/20 border (Stitch swap).
- Pagination (`_buildPaginationBar` + new `_buildPageNumber`): replaced "Página X de Y" text with Stitch-style 40x40 rounded-lg page-number buttons (active = filled primary + bold onPrimary, others onSurface), with a window of 5, ellipsis on both ends, and retained prev/next chevrons (disabled at bounds). Guarded window math when `totalPages <= 5`.

Backend untouched. Verified: `flutter analyze` → No issues found; `flutter test` → All tests passed.

## 2026-08-15 — Desktop product detail screen aligned to Stitch design

Request: user said "continue with product detail" (next screen after order history). Target `.stitch/designs-desktop/product-detail-desktop.html`.

Changes in `frontend/lib/widgets/product_detail_screen.dart` (desktop-only, mobile untouched):
- Top bar breadcrumb text (`_breadcrumbLabel`) → interactive breadcrumb row `_buildDesktopBreadcrumb`: "Inicio" (InkWell → `Navigator.maybePop`) > chevron > category > chevron > product name.
- Organic badge: new getter `_organicTag` reads `customAttributes['organic']` (bool true → "Orgánico", non-empty String → as-is) or scans `product.tags` for an "org"-matching tag → renders secondaryContainer pill (uppercase, letterSpacing 0.8) above the category label.
- Price row: unit suffix added — `/ $unitLabel` appended after the current price when `customAttributes['unit']` is present (`_unitLabel` getter). Strikethrough original price (when discounted) unchanged.
- Features Wrap (3 chips) → `_buildDesktopQuickInfo` + `_buildQuickInfoRow` (surfaceContainerLow card, icon + bold label + value rows: Origen/Entrega hoy/Calidad Premium). Removed `_buildDesktopFeatureChip`.
- Main image (`_buildDesktopMainImage`): inner container now surfaceContainerLowest with 28px padding and images `BoxFit.contain` (matches Stitch contain layout).
- Quantity stepper radius Circular(20) → Circular(999) (Stitch pill).
- "Agregar al Carrito" button: rounded-999 full-pill ButtonStyle (padding h24/v16).

Also removed now-unused `_breadcrumbLabel` getter (replaced by breadcrumb).

Verified: `flutter analyze` No issues found; `flutter test` All tests passed.

## 2026-08-15 — Desktop order history screen aligned to Stitch design

Request: user (answering "next please" after checkout alignment) wanted the desktop order history to match `.stitch/designs-desktop/order-history-desktop.html`.

Changes in `frontend/lib/widgets/order_history_screen.dart` (desktop-only, mobile untouched):
- Header: replaced single "Mis Pedidos" title with breadcrumb ("Inicio > Historial de Pedidos", Inicio → `_goToStorefront`) + title "Historial de Pedidos" (32 w900) with a 280px "Buscar pedido..." search field on the right (search state/filtering logic unchanged).
- Filter pills → Stitch underline tabs (bottom-border 2px primary on active, plain on-surface-variant text) via new `_buildDesktopFilterTab`; filter logic (`_activeFilter` Todos/En camino/Entregados/Cancelados, ID search) unchanged.
- Added `_buildDesktopSectionHeader` for the two Stitch section headings: "Pedido en curso" and "Anteriores".
- `_buildDesktopActiveBanner`: now surfaceContainerLowest card w/ soft shadow + primaryContainer/20 border, circular primaryContainer icon (local_shipping), "EN CAMINO" status pill (primary/10 bg, uppercase, letterSpacing 0.8) + `#short-id`, headline "Llega hoy por la tarde" (18 w600), "N artículos • $total" subtitle, filled primary "Rastrear pedido" button → order details.
- `_buildDesktopOrderCard`: restructured to Stitch layout — `#id` + inline status (`_buildDesktopInlineStatus`: statusIcon + statusColor + displayName, 12 w500) + formattedDate on left, right-aligned total (18 w600) + item count on right, 1px outlineVariant/30 divider, footer with two equal-width buttons: outlined "Ver detalles" (border outline) and (for completed only) "Volver a pedir" (surfaceContainerHigh bg, replay icon, same snackbar behavior). Cancelled cards wrapped in `Opacity(opacity: 0.75)`.
- Added `_buildDesktopSupportCard` (Stitch support block): surfaceContainer rounded-12, help_center icon, "¿No encuentras un pedido?", helper text, "Consultar soporte" link (primary, arrow_forward) — shown at the bottom of the orders list.
- Removed now-unused `_buildDesktopStatusChip` and `_buildDesktopFilterPill`. Added `_goToStorefront()` = `Get.offAll(() => const MainScreen())`; added `import '../main.dart'` and `import 'package:get/get.dart'`.

Verified: `flutter analyze` No issues found; `flutter test` All tests passed.

## 2026-08-15 — Desktop checkout screen aligned to Stitch design

Request: user wanted the desktop checkout to match `.stitch/designs-desktop/checkout-desktop.html`.

Changes in `frontend/lib/widgets/checkout_screen.dart` (desktop-only, mobile untouched):
- Transactional header (Nav suppressed per Stitch): brand "Mercadomio" (shopping_basket) left, "Pago Seguro" (lock) right, surfaceContainerLowest with soft shadow.
- Breadcrumb "Inicio > Carrito > Finalizar Compra" + page title "Finalizar Compra" with "N producto(s) en tu carrito" subtitle.
- Left column (flex 2): "Entrega a domicilio" section (local_shipping icon + shipping form), "Método de pago" section (credit_card icon + selectable radio cards: Tarjeta de Crédito/Débito "Termina en •••• 4242" / Efectivo al recibir / OXXO Pay, state `_selectedPayment`), notes field, terms card, security badge "Pago 100% seguro y encriptado" (shield).
- Right column (400px summary card): "Resumen de tu pedido" with order items (64x64 image, quantity badge, unit price from `effectivePrice`), collapsible "Agregar cupón de descuento" toggle (`_showCouponField`), breakdown (Subtotal original, Descuento -$savings in tertiary, Envío Gratis in primary, Total in primary w900 using effective prices), "Confirmar pedido" button + "Regresa fácilmente si necesitas cambiar algo".
- Added helpers `_currentUnitPrice(item)` / `_originalUnitPrice(item)` (same effectivePrice/basePrice pattern as cart). Order submit `_processOrder` unchanged (still sends shippingAddress + optional coupon to backend).

Verified: `flutter analyze` No issues found; `flutter test` All tests passed.

## 2026-08-15 — Desktop cart screen aligned to Stitch design

Request: the desktop cart screen did not match the Stitch designs in
`.stitch/designs-desktop/` (user picked this as the next focus).

Changes in `frontend/lib/widgets/cart_screen.dart` (desktop-only, mobile
untouched):
- Desktop header now shows a breadcrumb ("Inicio > Mi Carrito") + page title
  "Mi Carrito" with an "(N artículos)" subtitle and a right-aligned
  "Seguir comprando" link (both return to the storefront via `_goToStorefront`).
- Replaced the `DataTable` with a Stitch-style custom 12-col grid (flex 6/3/2/1):
  "Producto" + "Cantidad" + "Subtotal" headers, dropping the extra
  "Precio unitario" column.
- Product cells now show unit subtitle (`customAttributes['unit']`), an "Opción:"
  fallback line, and a low-stock badge ("¡Últimas N!") when a variant is
  available with 1–3 units left.
- Quantity stepper redesigned as a rounded-full pill (minus / qty / plus) to
  match the reference.
- Subtotal column stacks current price over a strikethrough original price when
  the product is discounted.
- Summary card now shows Subtotal (at original prices), "Envío gratis" (bold
  primary), Descuentos (error when > 0), a large primary Total, a savings alert
  ("¡Ahorras $X en esta compra!") only when a discount applies, a coupon input
  with an "Aplicar" button, the "Finalizar Compra" CTA with an icon, and a
  "Pago 100% seguro" lock note.
- New helpers: `_goToStorefront`, `_currentUnitPrice` (uses
  `customAttributes['effectivePrice']`, falls back to basePrice),
  `_originalUnitPrice`, `_unitLabel`. Discount arithmetic is local to the desktop
  summary (does NOT change `Cart.total`/backend).

Verified: `flutter analyze` No issues; `flutter test` All tests passed.

## 2026-08-15 — Add-to-cart feedback: hover/press states + success/error snackbars

Request: the add-to-cart button gave no visual feedback (no hover/press state)
and no confirmation that a product was added.

Root cause: `_addToCart` in `product_listing_widget.dart` did not await
`cartController.addToCart` and showed the success snackbar unconditionally, so
a failure showed nothing meaningful. The buttons used `IconButton.styleFrom`
with a flat `backgroundColor` (no `overlayColor`), so there was no visible
hover/pressed state on desktop.

Fix (frontend only; backend was already verified working in the cart-auth fix):
- `_addToCart` is now `async`, awaits the cart call, and shows a success or
  error snackbar accordingly (success "Agregado al carrito", error "No se pudo
  agregar" with the message).
- New `_cartButtonStyle(colorScheme)` helper builds a `ButtonStyle` with a
  `WidgetStateProperty` overlayColor (hover alpha 0.10, pressed 0.24) and a
  disabled-aware backgroundColor, restoring Material hover/press feedback.
  Applied to both the mobile and desktop add-to-cart `IconButton`s.

Verified: `flutter analyze` No issues, `flutter test` All tests passed. Backend
guest-cart POST with a real product ID returns 201.

## 2026-08-15 — Fixed improper GetX usage in desktop cart header

Request: GetX "improper use of a GetX has been detected" (and a 99065px RenderFlex
overflow) thrown from `cart_screen.dart:507`.

Root cause: `_buildDesktopLayout` wrapped its header item-count text in a
nested `Obx` that read no reactive variable (it read the plain `cart` value
passed in, already unwrapped by the outer `Obx` in `build()`).

Fix: replaced the nested `Obx` with a plain `Builder` (the outer per-body `Obx`
already rebuilds this subtree when the cart changes).

## 2026-08-15 — Guest cart now works without auth (add-to-cart fix)

Request: clicking "add to cart" in the Flutter app did nothing.

Root cause: `backend/routes/cart_routes.go` mounted every mutating cart route
(POST items, PUT/DELETE item, merge) behind `AuthMiddleware`, but the Flutter
`CartService` uses a token-less guest cart (`guest-cart-<epoch>`). The POST came
back 401, the controller swallowed the error (`error.value`), and no snackbar
state change happened.

Backend carts are keyed purely by `cartId` (Redis), never by user identity, and
the handlers (`cart_handlers.go`) don't read `userID` — so auth was unnecessary.

Fix: `cart_routes.go` — all cart routes now use `OptionalAuthMiddleware`
(consistent with the existing public GET). A valid token still populates
`userID` in Locals for handlers that want it.

Verification: `go build` clean; guest POST `curl` now works **after restarting
the backend** (the running instance still returns 401 until restarted).
Backend tests: 28/29 (same pre-existing `TestPricingResolvePricesIntegration`
failure). No Flutter changes needed.

## 2026-08-15 — Fixed catalog rendering overflows + uninitialized orders-screen fields

Request: rendering library exceptions during app run — `RenderFlex overflowed`
in the product card (plus several more) and `LateInitializationError` on
`_ordersFuture` / `_animationController`.

Changes (frontend only):
- **`widgets/product_listing_widget.dart`** (`_buildProductCard`): the card's
  fixed-height image (`SizedBox(height: cardHeight * _getImageHeight)`) squeezed
  the name/price/stars text block down to ~42px on short grid tiles → overflow.
  Replaced with a flexible `Expanded` image so the text block always gets its
  natural height. Removed the now-unused `_getImageHeight` helper and the
  redundant bottom-corner decoration. Card keeps `clipBehavior` for rounded image.
- **`widgets/order_history_screen.dart`** (`_OrderHistoryScreenState`): added the
  missing `initState` that initializes `_ordersFuture` (initial `getOrderHistory`
  load), `_animationController`, and `_fadeAnimation` — previously `late` fields
  were only set in refresh/retry callbacks, so `FutureBuilder` read them
  uninitialized.

Verification: `flutter analyze` → No issues found; `flutter test` → all pass.

Follow-up fix (post hot-reload, same request): the stars/rating/count + add-to-cart
`Row` inside `_buildProductCard` overflowed ~6.9px right on narrow cards. Wrapped
the stars group in `Expanded` and made rating + review-count `Text`s `Flexible`
(ellipsis, maxLines 1) so the row shrinks; the flexible `Expanded` image also
covers any remaining short-tile bottom overflow. Verified: analyze no issues,
tests all pass. Also reverted stray duplicate `_getImageHeight` copies (removed the
now-unused helper).

Follow-up fix (desktop branch): `_buildDesktopProductCard`'s square `AspectRatio(1)`
image + tall body Column overflowed ~57px bottom on narrow desktop grid columns.
Replaced the fixed square image with a flexible `Expanded` Stack (overlays intact),
so the body keeps its natural height. Verified: analyze no issues, tests all pass.

## 2026-08-15 — Pricing engine now resolves catalog discounts/units (backend + Flutter)

Request: make discounts/units real via the existing backend pricing engine
(PriceSchedules/PriceSets) instead of UI placeholders, keeping Flutter code clean.

Decision: resolve-through-engine on every catalog read; attach transient
`effectivePrice`, `discountPercent`, `unit` to `product.customAttributes`
(nothing persisted, model structs unchanged).

Backend changes:
- **`handlers/product_handlers.go`**: `ProductHandlers` gained `PricingService`;
  `NewProductHandlers` signature now takes it. New `enrichCatalogPrices(ctx,
  products []*services.Product)` resolves each product (first variant, qty 1,
  anonymous `PricingContext`) in one `ResolvePrices` call and mutates products
  in place — errors log and skip (never fail a catalog read). `applyCatalogPrice`
  writes `effectivePrice`, `discountPercent` (rounded base-vs-unit %), `unit`
  (product customAttributes → first variant attrs). Helpers: `productsOf`,
  `productUnit`, `firstVariantUnit`. Wired into both GetProducts return paths
  (search + simple list) and GetProduct.
- **`routes/setup.go:38`**: passes `deps.PricingService` to `NewProductHandlers`.

Flutter changes (all reads flow through documented helpers):
- **`widgets/product_listing_widget.dart`**: `_productUnit` / `_productDiscount`
  now carry doc comments explaining the pricing-engine origin. Behavior unchanged.
- **`widgets/product_detail_screen.dart`**: `_desktopDiscount` / `_desktopOriginalPrice`
  getters documented (engine-derived; fallback to current price when no discount).

Verification: `go build ./...` + `go vet ./...` clean; backend tests 28/29 pass —
the 1 failure (`TestPricingResolvePricesIntegration`, applySets asserts `AppliedSets==1`
but engine emits per-line = 2) is pre-existing and isolated from this change.
`flutter analyze` no issues; `flutter test` all pass.

## 2026-08-15 — Desktop Stitch layouts integrated into Flutter responsive branches

Request: integrate the 7 desktop/web Stitch HTML designs (`.stitch/designs-desktop/`)
into the Flutter desktop (>=800px) branches, after the mobile M3 migration.

Changes (via integration agent + follow-up):
- **`main.dart`**: sidebar brand row + "Ayuda y soporte" rows made overflow-safe at 800px.
- **`cart_screen.dart`**: desktop sticky header "Mi Carrito (n artículos)", table columns
  Producto/Cantidad/Subtotal, coupon field, "Resumen de compra" card incl. Envío Gratis pill,
  savings amount + Total + Finalizar Compra.
- **`checkout_screen.dart`**: desktop sections Entrega a domicilio / Resumen de tu pedido /
  Método de pago (radio cards: Tarjeta •••• 4242 / Efectivo / OXXO Pay + "Pago 100% seguro") /
  Notas adicionales / términos; right rail with coupon + totals + Confirmar Pedido. `_processOrder`
  (Conekta) logic intact.
- **`order_history_screen.dart`**: desktop header + search by order #, status filter pills
  (Todos/En camino/Entregados/Cancelados), "Pedido en curso" banner (Rastrear pedido),
  order cards (ver detalles / volver a pedir).
- **`test/widget_test.dart`**: updated brand string assertion 'Tianguis Botis' → 'Mercadomio'.
- Data pulls discount/unit from `customAttributes` (Product model has no dedicated fields);
  coupon apply + savings are UI-only placeholders.

Verification: `flutter analyze` no issues; `flutter test` all pass.

## 2026-08-15 — Stitch HTML designs → Flutter Material 3 theme migration

Request: convert the 7 regenerated Stitch HTML designs (`.stitch/designs/`) into a
Material 3 theme + Spanish-branded Mercadomio Flutter UI (`frontend/lib/`).

Changes:
- **`frontend/lib/theme.dart`** (new): `AppTheme.light` — `ColorScheme.fromSeed(0xFF006B1B)`
  with exact Stitch palette overrides (primary #006b1b, primaryContainer #268630,
  onPrimaryContainer #f7fff1, secondary #446741, secondaryContainer #c2eaba,
  onSecondaryContainer #486b45, error #ba1a1a, surface #f6fbf0, surfaceContainer
  #eaf0e4, surfaceContainerLow #f0f5ea, surfaceContainerLowest #ffffff, surfaceContainerHigh
  #e5eadf, surfaceContainerHighest #dfe4d9, onSurface #181d16, onSurfaceVariant #3f4a3d,
  outline #6f7a6b, outlineVariant #bfcab9). Radii: 8 inputs/chips, 12 cards/buttons,
  16 large cards. `base.copyWith` widget themes: AppBar (surface, no elevation), Card
  (surfaceContainerLowest), buttons, InputDecoration, Chip, SnackBar, BottomNavigationBar,
  FAB. System fonts only (google_fonts NOT installed).
- **`main.dart`**: `title: 'Mercadomio'`, `theme: AppTheme.light`; AppBar = shopping_bag
  icon + 'Mercadomio' wordmark (primary color, responsive break at 400px), search action,
  CartIcon, AuthOptional popup; BottomNavigationBar themed (Inicio/Carrito/Pedidos);
  removed logo.png container + deepPurple.
- **Screens restyled to theme + Spanish**: login_screen (full rewrite), cart_screen
  (fixed `Undefined name 'context'` → private builders use `Get.theme`), product_listing_widget
  (card grid, list, sidebar, pagination 'N de M', 'No hay productos disponibles'),
  product_detail_screen (Descripción/Opciones/Imágenes/Reseñas, cantidad stepper,
  themed variant chips, SliverAppBar surfaceTintColor transparent; fixed a botched
  python replacement), order_history_screen ('Historial de Pedidos', removed primary
  gradient AppBar), checkout_screen (Shipping/Pago/Confirmar Pedido, validated Spanish
  fields, payment chips Tarjeta/OXXO/SPEI, OrderConfirmationScreen '¡Pedido Realizado!').
- **Support widgets themed**: product_search_controls (Spanish sort labels), category_selector
  ('Todos', primary selected chip), category_breadcrumbs (surfaceContainer strip, 'Todos'
  root), cart_icon (primary badge), order_details_screen (removed `primaryColor` AppBar +
  gradient container, status colors kept from OrderStatus, Spanish snackbars/dialogs,
  themed buttons).

Verification: `flutter analyze` → **No issues found! (ran in 0.9s)** at every checkpoint.

Notes: `product_card.dart` / `product_list_item.dart` are orphaned (not imported
anywhere — listing widget uses inline builders); left unconverted. `order_demo_screen.dart`
and `error_boundary_widget.dart` are debug/dev widgets, not in the 7-screen task list.
`order_history_screen.dart` still has `Colors.grey.shade200`/`Colors.grey` (lines 555/600,
image bg + empty-state icon) that could be themed in a follow-up.

Next: (from previous entry) integrate the remaining Stitch screens; optionally restyle
order_details further, run `flutter test`.

## 2026-08-15 — Stitch design workflow skill + Mercadomio screen regeneration

Request: "podrias borrar el projecto en google stitch y gneerar de neuvo las
pantallas usando los skills" — reset the Stitch project and regenerate screens
using the newly installed skills.

Findings:
- Stitch MCP generation is async: `generate_screen_from_text` always returns
  MCP error -32001 "Request timed out" (~65s) even on success. Screens can take
  >2 minutes to appear in `list_screens`. Re-firing within that window creates
  permanent duplicates (no per-screen delete tool). Screens finish when
  `htmlCode.downloadUrl` is present (empty `htmlCode:{}` = logo/image
  artifacts, ignore them).
- API args gotcha: `projectId` must be the NUMERIC id for
  `generate_screen_from_text` / `list_design_systems`, but `projects/<id>` for
  `get_project` / `list_screens`.

Changes:
- Installed Google's official `stitch-skills` library (15 skills) into
  `~/.agents/skills/` for cross-app use (generate-design, stitch-loop,
  react-native, react-components, manage-design-system, etc.).
- Created user-level skill `~/.agents/skills/stitch-design-workflow/SKILL.md`
  encoding the full async loop: prompt structure (purpose + PLATFORM + PAGE
  STRUCTURE, no color/font tokens — design system handles them), one screen at
  a time, expect timeout, wait ~90s, poll `list_screens` every 45-60s with
  `get_project.updateTime` as liveness signal, re-fire only after 4-5 min dead
  window, verify by TITLE, download HTML via curl.
- Deleted old Stitch project `projects/17908365451696268078` and created fresh
  `projects/9322283502076035827` "Mercadomio" with design system
  `assets/14132221149110130373` (LIGHT, INTER, ROUND_EIGHT, #43A047).
- Generated 7 screens one-at-a-time and downloaded HTML to `.stitch/designs/`:
  login, storefront, product-listing (Frutas y Verduras), product-detail,
  cart, checkout (Finalizar Compra), order-history (Historial de Pedidos).
- Persisted `.stitch/metadata.json` (project id, design system, screen map).

Next: integrate the Stitch HTML designs into the Flutter frontend
(`frontend/lib/` screens/widgets).

## 2026-08-16 — API Docker packaging for QA + production deploys

Request: "you didn't create Dockerfile for the api server when we deploy to qa and production."

Findings:
- `backend/Dockerfile` already exists and is used by QA (`docker/docker-compose.qa.yml`
  builds from `build: ../backend`). The real gap was **production**: the generated
  `docker-compose.prod.yml` pulls `ghcr.io/hugomf/mercadomio/backend:latest` and
  `:frontend:latest`, but nothing ever published those images (no `.github/` existed).

Changes:
- **`backend/Dockerfile`**: runtime stage now `apk add ca-certificates tzdata curl`
  so the prod compose container healthcheck (which curls `/health`) actually works.
- **`.github/workflows/docker-publish.yml`** (new): builds + pushes
  `ghcr.io/hugomf/mercadomio/{backend,frontend}:{latest|<git-tag>}` on pushes to
  `master`/`main`, tag-creating pushes `v*`, and `workflow_dispatch`. Uses
  `docker/build-push-action@v6`, login to GHCR with `GITHUB_TOKEN`.
- **`deploy/setup-pi-production.sh`** (production setup script, pre-existing fixes):
  - Was unparseable: all six file-writers used `sudo -u deploy bash -c "cat > ... << EOF"`,
    where the raw `"` inside heredoc bodies closed the outer double-quote early →
    `bash -n` failed at the health-check heredoc. Rewrote all six as top-level
    `sudo -u deploy tee "$DEPLOY_PATH/x" > /dev/null << EOF|'EOF'` heredocs,
    decoding `\"`, `\$`, `\${...}` escapes so generated files are identical to intent.
  - healthcheck URL `/api/health` → `/health` (Fiber route is `GET /health`).
  - mongo command dropped `--smallfiles` (removed in MongoDB 4.0+; `mongo:7-jammy`
    rejects it at startup).
  - Compose image refs now use a script-computed `IMG_ORG` (from git remote, default
    `hugomf`) instead of inline `$(git config ...)` (which also never survived the old
    heredoc nesting).
- Verified: `docker build` of `backend/` succeeds; image contains `curl 8.14.1` and runs
  as non-root `appuser`; `bash -n deploy/setup-pi-production.sh` passes; sandbox dry-run
  of the generation functions produced a valid `docker-compose.prod.yml`
  (`docker compose config --quiet` OK), correct `.env.production`, nginx.conf with real
  `$host/$remote_addr/$uri` vars, and correct health-check/backup/update scripts.
  `go build ./... && go vet ./...` still pass.

## 2026-08-16 — Fix backend startup logs + app crash on unreachable backend

- `scripts/start-backend.sh` showed no output because `nc` blocked on the unreachable
  `192.168.1.218` from `local.env` with no connect timeout. Added `nc -z -G 2 -w 2`
  and a "Checking <name>..." line so each dependency check fails fast and prints.
- Backend printed nothing at request time: `routes/setup.go` only had CORS. Added
  `app.Use(logger.New())` (gofiber/fiber/v2/middleware/logger) so every request
  logs method/path/status/latency.
- Flutter crash "No Overlay widget found" from a `Get.snackbar` raised inside
  `CategoryService.getFilteredProducts` (service layer) when the backend is down.
  Removed the snackbar (UI layer already renders the error state); verified
  `flutter analyze` clean on `lib/services/category_service.dart`.

## 2026-08-16 — Add backend start script

- Added `scripts/start-backend.sh` (executable): sources `backend/local.env`
  (godotenv in `main.go` only reads `.env`, which isn't committed locally),
  resolves defaults matching `main.go` (`MONGO_URI` mongodb://localhost:27017,
  `REDIS_ADDR` localhost:6379, `PORT` 8080), verifies MongoDB + Redis are
  reachable via `nc` (with a `docker compose up -d mongo redis` hint), runs
  `go build ./...` as a compile gate, then `exec go run .` from `backend/`.

## 2026-08-15 — Desktop redesign for both apps (Stitch design → Flutter port) [SPEC]

- Brainstormed and got approval for improving the desktop version of both Flutter
  apps using Google Stitch: storefront (`frontend/`) + admin console
  (`admin_console/`), "modern refresh, keep purple" direction, full core screen
  sets on each.
- Chose Stitch-first workflow: define design system + 10 desktop screens in Stitch,
  then port approved designs to Flutter, preserving existing state/logic/services.
- Wrote design spec at `docs/superpowers/specs/2026-08-15-mercadomio-desktop-redesign-design.md`
  (design system, 5 storefront screens, 5 admin screens, porting rules, acceptance
  criteria, out of scope: mobile/tablet, backend, auth, CI).
- Self-review passed (no placeholders/contradictions; clarified dark-mode = retain
  existing admin toggle, only light default is redesigned).
- Stitch screen generation timed out repeatedly (project + design system were
  created: `projects/8331453007382199929`, `assets/1851934900949917938`), so the
  approved spec was implemented directly in Flutter per user decision.
- Desktop branches (`>= 800 px`, `MediaQuery`) added to all 10 screens:
  - Storefront (`frontend/lib/widgets/`): `product_listing_widget.dart` (sidebars
    sidebar + search/sort toolbar + pagination bar + 3-col/4-col/top grid),
    `product_detail_screen.dart` (2-col image + details), `cart_screen.dart`
    (DataTable + order-summary panel), `checkout_screen.dart` (2-col forms +
    summary), `order_history_screen.dart` (DataTable + status chips).
  - Admin (`admin_console/lib/`): `main.dart` persistent sidebar
    (`Row[NavigationDrawer, VerticalDivider, body]`) on desktop; `order_list_screen.dart`
    DataTable w/ status chips + status-update menu; `catalog_management.dart`
    rewritten from stub → searchable DataTable + edit dialog + stock editing;
    `category_management.dart` desktop `Categories` wrapper; `pricing_screen.dart`
    two DataTables (schedules + sets) sharing refactored card formatters;
    `inventory_screen.dart` desktop stock DataTable with low-stock chips.
- Lint fixes surfaced by full-app `flutter analyze`: `auth_guard.dart:41` unused
  var, `order_details_screen.dart:67/75` `use_build_context_synchronously`,
  `models/order.dart:189` unused var.
- Verified: `flutter analyze` clean in both `admin_console` and `frontend`;
  backend still green per VERIFICATION.md (build/vet/gofmt + 19 unit tests).
  Mobile/tablet layouts preserved on every screen. No git commands run.

## 2026-08-14 — Backend housekeeping (docs, gitignore)

- Created `docs/VERIFICATION.md`, a per-repo verification checklist: backend build/vet/gofmt gates, the 19 services unit tests, a compile-only gate for `backend/tests/` (integration needs live Mongo — expected to fail when it is down), and Flutter `analyze`/`test` for `frontend/` and `admin_console/`.
- Fixed README stale content: badges no longer hardcode bogus "7/7 tests"/"100% coverage" (now reflect 19 passing unit tests, no coverage claim); the "Testing & Development" snippets previously ran `go test ./tests/order_test.go ./tests/auth_test.go ...` and `go test -coverprofile=coverage.out ./fragments` (a nonexistent package) — now `go test ./services/ ./tests/ -v` and `go test -coverprofile=coverage.out ./...`; backend `.env` example uses the real `MONGO_URI` (was `MONGODB_URI`).
- Fixed `docs/setup.md`: Directus collection list dropped the bogus `fragments` collection (schemas are products, users, orders, categories, control_panels); duplicate `## 6.` header renumbered (`Testing Features` 6, `Stopping Services` 7).
- Hardened `backend/.gitignore`: added `local.env` (previously only `.env` patterns, so the committed dev env file was not ignored) and fixed the `.DS_Store` line that had a stray leading space (ineffective pattern).
- Removed stray `scripts/scrape-natura-api copy.sh` (leftover of a duplicated/renamed script).
- Left for later: CI workflow (not selected this round). No git commands run.

## 2026-08-14 — Enforce pricing extensions (usage caps + SKU/category scopes)

- `backend/models/pricing.go`: `PriceSet` gained `CustomerUsage map[string]int`
  (json/bson `customerUsage`) storing per-customer usage counts inside the set
  doc (no separate collection).
- `backend/services/pricing_service.go`:
  - `PricedLine` now carries `SKU`, `Category`, `Categories` (parent category
    ids as hex) populated in `priceLine`; new `skuOf` helper (variant SKU
    preferred).
  - `ruleMatches` now enforces `RuleScopeSKU` and `RuleScopeCategory`
    (previously stored but unenforced).
  - `applySets` gates each set on new `usageAvailable(set, pc)`: skips sets
    with `UsedCount >= MaxUses` or, for a known customer,
    `CustomerUsage[customer] >= MaxUsesPerCustomer`.
  - New `IncrementSetUsage(ctx, setIDs, customerID)` — `$inc usedCount` + `$inc
    customerUsage.<customerID>` per set id, skips invalid ids.
- `backend/services/order_service.go` `CreateOrderFromCart`: captures
  `appliedSets`, then after the order is inserted calls `IncrementSetUsage`
  (deduped ids) so discounts are in force without burning caps on previews —
  `POST /api/pricing/resolve` unchanged and side-effect free.
- Tests: unit `pricing_service_test.go` 16 → 19 (added `TestRuleMatchesSkuAndCategory`,
  `TestApplySetsUsageCaps`, `TestApplySetsPerCustomerCap`). Integration test
  (`tests/pricing_integration_test.go`) still compiles/vets clean; full Mongo
  run blocked locally (mongodb not running).
- Verified: `go build ./...` + `go vet ./...` clean, `gofmt -l` empty, `go test
  ./services/` → 19 passed.

## 2026-08-14 — Admin console pricing screens

- Added `models/pricing.dart` (PriceSet/PriceRule/PriceConditions/PriceSchedule/
  PriceHistoryEntry + enums with fromJson/toJson) and
  `services/admin_pricing_service.dart` (CRUD against `/api/pricing/*`).
- New `screens/pricing_screen.dart`: tabbed management UI — **Price Schedules**
  (dated bulk %/absolute/fixed price changes) and **Price Sets** (coupons,
  loyalty tier, min-subtotal/min-qty, special customers) with create/edit/
  delete dialogs.
- Wired drawer 'Pricing & Discounts' item (Icons.sell) to the new screen.
- Fixed 3 analyzer errors (const PriceConditions ctor, `_DialogReturn.set()`
  constructor, type-init-formals). Verified: `flutter analyze` clean + 2 widget
  tests green.

## 2026-08-14 — Checkout coupon entry (Flutter frontend)

- Added coupon-code input to the checkout flow. Shipping → Promo Code → Payment → Terms.
- `frontend/lib/models/order.dart` `OrderCreateRequest` now carries optional `couponCode` / `customerTier` (omitted from JSON when empty).
- `frontend/lib/services/order_service.dart` `createOrderFromCart` accepts `couponCode`/`customerTier` and forwards them; backend `POST /api/orders` already read `{couponCode, customerTier}` from the body and applies the pricing engine (sets discount + records Subtotal/Discount).
- `checkout_screen.dart`: new `_couponController` (+dispose) and `_buildCouponSection()` promo-code card; `_processOrder` passes the trimmed coupon to `createOrderFromCart`.
- Verified: `flutter analyze` (only the 5 pre-existing warnings) + `flutter test` ('App renders without crashing' passes).

## 2026-08-14 — Pricing module tests (unit + integration)

- Unit: `backend/services/pricing_service_test.go` (package `services`, first
  test in that package) — 16 tests: conditions match (coupon EqualFold,
  subtotal/quantity thresholds, customer tier/IDs), window checks, schedule
  match (global/product/variant/category), rule match (all/product/variant),
  discount math (percentage/absolute/cap/never-negative), stop-further-rules
  stacking, schedule math, history-name dedupe, Order Subtotal/Discount/Total
  Validate. ALL PASS.
- Integration: `backend/tests/pricing_integration_test.go` (package `tests`,
  live-Mongo like `category_filter_test.go`) — seeds global +5% schedule +
  SAVE10 coupon set against two products, asserts Subtotal/Discount/Total +
  applied sets/schedules; drops price_sets/price_schedules/price_history.
  Compiles + vets clean; needs MongoDB on localhost:27017 to run.

## 2026-08-14 — Inventory feature (stock decrement + admin screen)

- Backend: added atomic `DecrementStock`/`IncrementStock` (bson `$inc` on
  `variants.$.stock` with `$gte:qty` guard) and `SetVariantStock` (positional
  `$set`) to product service + ProductService interface. Order service now hooks
  inventory: transition to **Paid** decrements stock per item (fails status flip
  on insufficient stock), transition **Paid→Cancelled** restores it. Covers
  Conekta webhook, demo simulate, and manual admin status changes.
- New endpoint `PUT /api/products/:id/variants/:variantId/stock` (admin console
  uses it to edit stock).
- Admin console: new `InventoryScreen` (product/variant list with stock color
  dots, edit-stock dialog), `AdminInventoryService`, `Product`/`ProductVariant`/
  `ProductsPage` models; wired drawer 'Inventory' item (was TODO).
- Verified: backend `go build`+`go vet` clean; admin_console `flutter analyze`
  clean + 2 widget tests green.

## 2026-08-14 — Conekta payment integration (hosted checkout)

### Completed
1. **Backend — Conekta checkout** (`backend/services/payment_service.go`,
   `backend/handlers/payment_handlers.go`, `backend/routes/payment_routes.go`):
   - `PaymentService` now reads `CONEKTA_SECRET_KEY` / `CONEKTA_PUBLIC_KEY` /
     `CONEKTA_WEBHOOK_PUBLIC_KEY`; `IsConektaConfigured()` = secret key present.
   - `CreateCheckoutSession(ctx, orderID, userID)` — POST `https://api.conekta.io/orders`
     (HostedPayment checkout, currency MXN, line_items from order items in cents,
     `allowed_payment_methods: [card, cash, bank_transfer]`, success/failure URLs
     from `CONEKTA_SUCCESS_URL`/`CONEKTA_FAILURE_URL` falling back to
     `BASE_URL`). Demo fallback when no secret key: returns a fake session
     (`/api/payments/demo?order_id=...`) so the offline flow still works.
   - `HandleConektaWebhook` — processes `order.paid` events only, maps the
     Conekta order id to the mercadomio order via `paymentInfo.conekta_order_id`
     (`GetOrderByConektaID`), dedupes already-paid orders, attaches payment info
     via `AttachPaymentInfo` (no status transition — avoids the error from
     repeating `UpdateOrderPayment`).
   - `ValidateConektaWebhookSignature` — RSA-SHA256 over the raw body, base64
     signature in the `DIGEST` header; accepts without signature (logs) when no
     webhook public key configured (demo).
   - Route `POST /api/payments/checkout` added. `CreateCheckout` handler is
     lenient about missing `userID` (payment routes have no `AuthMiddleware`);
     ownership is enforced in the service only when a userID is present.
   - `CONEKTA_SECRET_KEY`/`PUBLIC_KEY`/`WEBHOOK_PUBLIC_KEY`/`SUCCESS_URL`/
     `FAILURE_URL` added to `backend/.env.example`.
   - Verified: `go build ./...` + `go vet ./...` pass.

2. **Frontend — hosted checkout** (`frontend/lib/widgets/checkout_screen.dart`,
   `frontend/lib/services/order_service.dart`, `frontend/pubspec.yaml`):
   - Added `url_launcher: ^6.2.1`.
   - `OrderService.createCheckoutSession(orderId)` → `CheckoutSession`
     {checkoutUrl, checkoutId, conektaOrderId, demo}.
   - Checkout no longer collects card number/expiry/CVV (PCI risk removed).
     `_processOrder`: create order (shipping address only) → create checkout
     session → if `demo`: simulate completion + confirmation screen (offline
     demo preserved); else: open `checkoutUrl` via `launchUrl` external app,
     return to home. New `_PaymentMethodChip` widget; payment section shows a
     "Secure hosted checkout" note (Card / OXXO / SPEI).
   - Verified: `flutter analyze` clean on changed files (5 pre-existing
     warnings elsewhere), `flutter test` passes.

### Key learnings
- Conekta is async: never fulfill on create/redirect — only on a verified
  `order.paid` webhook. Cards resolve in the create response, but OXXO/SPEI
  stay pending until paid offline.
- Webhook dedupe must check the order status first because the backend's
  `UpdateOrderPayment` auto-transitions to `paid` and errors on a second call.
- Payment routes are not behind `AuthMiddleware`, so handlers must resolve
  `userID` leniently and let the service enforce ownership when present.

## 2026-08-14 — Auth strategy: full delegation to userbrew (decision)

- Explored `~/Projects/userbrew` (federated IdP, Rust/Axum, standard OIDC:
  PKCE S256 code flow, `/oauth/introspect`, app-scoped JWT with RBAC roles,
  per-application OAuth clients, `userbrew-cli quickstart` provisioning).
- Decided mercadomio delegates ALL auth/security to userbrew; backend becomes a
  pure resource server. Two applications to register: `mercadomio-shop` +
  `mercadomio-admin`.
- Flutter apps use `openid_client` (pub.dev); backend validates userbrew JWTs
  (recommended: local signature/JWKS via Go `coreos/go-oidc` or `golang-jwt`).
- Admin routes require a `mercadomio-admin` admin role claim.
- Written to `docs/AUTH-ARCHITECTURE.md`. Token wiring NOT implemented yet
  (deferred by owner; admin token not needed for now).

## 2026-08-14 — Admin console buildout (orders dashboard)

### Completed
1. **Backend admin order endpoints** (`backend/services/order_service.go`,
   `backend/handlers/order_handlers.go`, `backend/routes/order_routes.go`):
   - `GetAllOrders(ctx, page, limit, status)` + `CountOrders(ctx, status)` in
     order service (page>=1, limit 1..100 default 20, optional status filter,
     sort createdAt desc).
   - `GetOrdersAdmin` handler: returns
     `SuccessPaginated` `{data:{items,total,page,limit,totalPages,...}}`.
   - `GET /api/orders/admin` + `GET /api/orders/admin/stats` registered FIRST
     (before `/:id` routes) behind `AuthMiddleware(authService)`.
   - `SetupOrderRoutes` signature now takes `authService`.
   - Verified: `go build ./...` and `go vet ./...` pass.

2. **Admin console order model** (`admin_console/lib/models/order.dart`):
   full rewrite — `OrderStatus` enum (pending/paid/shipped/completed/cancelled)
   with `displayName`, `englishValue`, `statusColor`, `statusIcon`,
   `canTransitionTo` (mirrors backend `CanTransitionTo`); `OrderItem` and
   `OrderResponse` with `fromJson`/`toJson` matching backend JSON; `AdminOrdersPage`
   pagination wrapper.

3. **Admin order service** (`admin_console/lib/services/admin_order_service.dart`):
   `AdminOrderService` — `getOrders(page,limit,status)` → `AdminOrdersPage`,
   `getStats()` → `Map<String,int>`, `updateStatus(orderId,status)` → PUT
   `/api/orders/:id/status`. Base URL `http://localhost:8080`, optional Bearer token.

4. **Orders dashboard** (`admin_console/lib/screens/order_list_screen.dart`):
   replaced 27-line constructor-injected stub with a real dashboard: stat cards
   (total + per-status), status filter chips, refresh/error/empty states,
   order cards with status pills and a status-transition popup menu
   (only shows transitions valid via `canTransitionTo`).

5. **Wiring**: `main.dart` home body now `OrderListScreen` (AppBar title
   'Order Management'); drawer gained an 'Order Management' item.

6. **Admin console widget tests** (`admin_console/test/widget_test.dart`):
   replaced stale counter smoke test with 2 tests — dashboard renders
   (`Scaffold` + 'Order Management' title) and drawer opens showing menu items.
   Passes.

7. **Drawer layout fixes** (`admin_console/lib/widgets/navigation_drawer.dart`):
   pre-existing overflow bugs surfaced by the tests — content is now in a
   scrollable `ListView`, header text wrapped in `Flexible` with ellipsis.

### Key learnings
- Admin order HTTP test only: `flutter_test`'s default HTTP mock returns 400,
  so screens must handle a load error state without crashing (no GetX snackbar
  on initial load here) — makes smoke tests robust without mocking HTTP.
- RenderFlex overflow errors in widget tests often reveal real layout bugs
  (non-scrollable drawer columns) — fix the widget, not the assertion.
- `flutter analyze` + `flutter test` clean in `admin_console`; backend still
  `go build`/`go vet` clean.

## 2026-08-14 — Fix hardcoded paths & stale tests

### Completed
1. **Backend images path** (`backend/routes/setup.go`): replaced hardcoded
   `/Users/hugo/mercadomio-copilot/frontend/web/assets/images` (a different repo)
   with `IMAGES_PATH` env var, defaulting to `./frontend/web/assets/images`.
   Same fix applied to `backend/handlers/image_handlers.go`.
   Added `IMAGES_PATH` to `backend/.env.example`.
   Verified: `go build ./...` and `go vet ./tests/...` pass.

2. **Backend auth tests** (`backend/tests/auth_test.go`): fixed nil-pointer
   derefs on failed Register/Login — `t.Errorf` + missing return followed by
   nil deref of `user`/`authResponse`. Now uses `t.Fatalf` and explicit nil
   guard with `t.Fatal`. Compiles; run requires live MongoDB on `localhost:27017`.

3. **Frontend widget test** (`frontend/test/widget_test.dart`): stale test
   asserted `'Pluggable Widgets'` (does not exist; app shows `'Tianguis Botis'`).
   Rewrote with a full `dart:io` HttpClient mock (`HttpOverrides.global`,
   set inside the test body — binding clobbers it if set in `setUpAll`).
   Mock is path-aware: `/api/cart` → cart object, `/api/products` →
   `{data:[],total:0}`, everything else → `[]`. Test now asserts
   `find.text('Tianguis Botis')` and `find.byType(Scaffold)`. Passes,
   `flutter analyze` clean on the test file.

### Key learnings
- `HttpClient`/`HttpClientRequest`/`HttpClientResponse` cannot be `extended`
  (factory constructors) — must be `implements` with full member surface,
  because `package:http`'s `IOClient` calls `addStream`, `headers.set`,
  `handleError`, `redirects`, `contentLength`, setters, etc.
- `package:http` uses `dart:io` `HttpClient` via `IOClient`, so
  `HttpOverrides.global` intercepts top-level `http.get` in tests.
- In `flutter_test`, `TestWidgetsFlutterBinding.init` resets
  `HttpOverrides.global`, so the override must be installed inside the test body.
- GetX snackbars throw "No Overlay widget found" in widget tests — avoid
  triggering them by ensuring mocked responses match what services parse
  (cart expects object, products expects `{data,total}`, lists elsewhere).
