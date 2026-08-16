# Mercadomio Desktop Redesign (Stitch → Flutter) — Design

Date: 2026-08-15
Status: Approved by user

## Goal

Improve the desktop experience of both Mercadomio Flutter apps by designing a modern
desktop layout in Google Stitch, then porting the approved screens into the Flutter
codebase while preserving all existing state/logic/API behavior.

## Approach

Stitch-first, then Flutter:

1. Create a Stitch project `mercadomio desktop redesign` and a design system.
2. Generate the 10 desktop screens via Stitch text prompts (5 storefront + 5 admin).
3. Iterate on the Stitch screens until they meet the design bar.
4. Port each approved design into the matching existing Flutter screen.

## Design System (Stitch)

- Primary: modern purple seed (e.g. `#6B4EFF`–`#7C4DFF` family), Material 3.
- Type: modern sans body (Manrope/Inter) + bold display weights for headings.
- Spacing: 8px base scale; generous section padding on desktop.
- Shape: 12px corner radius on cards/panels.
- Modes: light by default, dark-mode support retained.
- Imagery: product-photo-forward cards.

## Storefront Desktop (frontend/) — 5 screens

1. **Home / Product listing**
   - Top nav bar: logo, global search, cart icon, account menu.
   - Left category sidebar (persistent on desktop).
   - Filter/sort toolbar above a responsive product-card grid (4-col @ ≥1920, 3-col @ 1280–1919).
   - Pagination below the grid.
   - Replaces the current one-column desktop branch in `frontend/lib/main.dart` (`HomeScreen`, line ~232).
2. **Product detail**
   - Two columns: large product image + title/price/SKU/stock/quantity/add-to-cart.
   - Related-products strip below.
3. **Cart**
   - Desktop table layout: item image/name, quantity stepper, unit/line price.
   - Right order-summary side panel.
4. **Checkout**
   - Two columns: address + payment forms; order summary panel.
   - Payment provider UI (Stripe/Conekta) retained from existing `checkout_screen.dart`.
5. **Order history + details**
   - Desktop data table (id, date, total, status chip) with a details drawer.

## Admin Console Desktop (admin_console/) — 5 screens

1. **Order list**
   - Persistent left navigation drawer (consolidate current drawer behavior).
   - Filterable orders data table with status chips.
2. **Catalog management**
   - Product data table with search + product edit dialog.
3. **Category management**
   - Category list/tree with add/edit/delete.
4. **Pricing**
   - Price-set and schedule data tables; rule editor panel.
5. **Inventory**
   - Stock-level table with inline quantity editing.

## Porting Rules

- Preserve all existing Flutter state, services, controllers, and API contracts.
- Replace layout + styling to match the approved Stitch screens; keep widget/structure names
  where practical to limit churn.
- Keep responsive behavior: the redesign targets desktop breakpoints (801px+); existing
  mobile/tablet layouts should not regress.
- Follow existing code conventions (GetX, responsive_framework, cached_network_image, etc.).

## Acceptance Criteria

- Stitch project contains the 10 designed desktop screens matching the design system.
- Storefront desktop screens functionally equivalent to current behavior (browse, search,
  filter, cart, checkout, orders) with new layout.
- Admin desktop screens functionally equivalent (list/filter/edit/pricing/inventory).
- `flutter analyze` clean in `frontend/` and `admin_console/`; existing tests pass
  (`flutter test` where present).
- `docs/VERIFICATION.md` checklist honored; `docs/SESSION_LOG.md` updated.

## Out of Scope

- Mobile/tablet layout redesigns.
- Backend API changes.
- Auth screens.
- CI workflow.