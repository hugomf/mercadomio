# MercadoMío 🏪

![Build](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

## Complete E-commerce Platform 🌟

A Mexican grocery e-commerce platform with a Go backend, two Flutter clients
(storefront + admin console), and a federated identity provider.

- **Backend**: Go + Fiber + MongoDB + Redis
- **Storefront**: Flutter (web/native), Material-based UI, Spanish
- **Admin console**: Flutter app for staff (catalog, inventory, orders, pricing)
- **Auth**: OIDC via [userbrew](https://github.com/sonnora-mx/userbrew) (PKCE)
- **Payments**: Conekta hosted checkout, with Stripe webhooks retained
- **Images**: imgvault service for product image storage/transformation

## Components

| Service | Tech | Notes |
|---|---|---|
| `backend/` | Go / Fiber | Resource server, port 8080 |
| `frontend/` | Flutter | Customer storefront |
| `admin_console/` | Flutter | Admin / staff console |
| userbrew | Rust / Axum | External IdP (OIDC) |
| imgvault | — | External image service |
| MongoDB + Redis | — | Data + cache/eventing |

## Run it

Local dev uses the scripts in `scripts/` (which load `backend/local.env`):

```bash
# Full dependent stack (Mongo, Redis, platform services) + backend
./scripts/start.sh

# Storefront (Flutter web)
./scripts/frontend.sh

# Admin console (Flutter web)
./scripts/admin-console.sh

# Everything in one terminal layout
zellij ... # see scripts/layout.kdl
```

Seeds are in `seed/` (e.g. `seed/seed_grocery.sh`); `seed/scrape-natura-api.sh`
imports the product catalog.

Multi-environment deployment (dev/qa/prod) lives in `platform/` and is driven by
`deploy.sh` + `scripts/publish-images.sh` + `scripts/setup-userbrew.sh`.
See `docs/setup.md` and `docs/SESSION_LOG.md`.

## Backend

```bash
cd backend
cp .env.example .env   # or backend/local.env via scripts/start.sh
GOROOT= go build ./...          # builds against the repo Go toolchain
GOROOT= go vet ./...
go test ./...
go run main.go                   # serves on :8080, /health
```

> Note: AGENTS.md documents that the checked-out `go` may point at an older
> gvm toolchain. Build with `GOROOT=` unset to use the updated one, or verify
> `go version` first.

## API

Public/paginated endpoints under `/api`:

- `GET /api/products` — product listing w/ search (`q`, `category`, `minPrice`,
  `maxPrice`, `type`, `sort`, `order`)
- `GET /api/products/:id` — product detail
- `GET /api/categories` — category tree (nested, image-resolved)
- `GET /api/cart/:cartId` and cart mutation endpoints (optional auth)
- `GET /api/orders`, `GET /api/orders/:id`, `POST /api/orders`
- `GET /payments/confirmation`, `/payments/cancelled` — provider redirect pages

Customer-identity endpoints under `/api/auth` (userbrew-token protected) cover
profile, addresses, payment methods, and wishlist.

Admin-only endpoints (require the `mercadomio-admin` OIDC audience/role):

- `PUT /api/orders/:id/status`, `GET /api/orders/admin`, `GET /api/orders/admin/stats`
- `POST/PUT/DELETE /api/products*`, `/api/categories*`
- `/api/pricing/*` price sets / schedules / history / resolve
- `/api/analytics/*` cart, conversion, product-view, and search analytics

Payments use Conekta hosted checkout (`POST /api/payments/checkout`) with
webhook + signature verification; Stripe PaymentIntent endpoints and webhooks
are retained.

## Testing

```bash
cd backend && go test ./...
cd frontend && flutter test
cd admin_console && flutter analyze
```

## More docs

- `docs/api-documentation.md` — API reference
- `docs/AUTH-ARCHITECTURE.md` — OIDC/userbrew auth design
- `docs/ROADMAP.md` — development roadmap
- `docs/CHANGELOG.md`, `docs/SESSION_LOG.md` — change history