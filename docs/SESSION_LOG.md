# Session Log

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
