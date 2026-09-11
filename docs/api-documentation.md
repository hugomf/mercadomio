# MercadoMío API Documentation

## Base URL

Local development: `http://localhost:8080`
API routes are namespaced under `/api` (except provider redirect pages at
`/payments/confirmation` and `/payments/cancelled`).

## Authentication

Authentication is delegated to **userbrew** (OIDC). Bear a userbrew token:

```
Authorization: Bearer {OIDC_JWT}
```

- Tokens validated by the backend via OIDC discovery/JWKS.
- The `mercadomio-admin` audience/role gates admin-only routes (403 otherwise).
- Public routes (catalog, cart, categories, products) do not require a token.

## Products

`GET /api/products` — List and search products
- Query params:
  - `page` (default 1), `limit` (default 20)
  - `q` — full-text/search query (routes to the SearchService pipeline)
  - `category` — comma-separated category **ObjectIDs** (hierarchical, includes
    child categories; falls back to legacy name regex when not IDs)
  - `minPrice`, `maxPrice`, `type`
  - `sort` — `name`, `basePrice`, `createdAt`, `updatedAt` (default `name`)
  - `order` — `asc`, `desc` (default `asc`)
- Effective prices (`effectivePrice`, `discountPercent`, `unit`) are computed
  per-request through the pricing engine and attached to `customAttributes`.

`GET /api/products/:id` — Product detail (also publishes a product-view event
for analytics)

`POST /api/products` — Create product (admin)
`PUT /api/products/:id` — Update product (admin)
`DELETE /api/products/:id` — Delete product (admin)
`PUT /api/products/:id/variants/:variantId/stock` — Adjust variant stock
`GET /api/products/:id/reviews` — List product reviews
`POST /api/products/:id/reviews` — Create review (authenticated)
`GET /api/products/:id/related` — Related products

## Categories

`GET /api/categories` — Category tree. Returns a nested structure:
```json
[ { "id": "...", "name": "Frutas", "slug": ..., "imageUrl": ...,
    "children": [ { "id": "...", "name": "Manzanas", ... } ] } ]
```
Image URLs are resolved through the imgvault proxy on the request base URL.

`GET /api/categories/search?name=` — Search categories by name
`POST /api/categories` — Create category (admin)
`PUT /api/categories/:id` — Update category (admin)
`DELETE /api/categories/:id` — Delete category (admin)

## Cart

Cart is Redis-backed, keyed by cart ID (`user_<id>` after login).

`GET /api/cart/:cartId` — Get cart contents
`POST /api/cart/:cartId/items` — Add item `{productId, variantId?, quantity}`
`PUT /api/cart/:cartId/items/:productId` — Update quantity `{quantity, variantId?}`
`DELETE /api/cart/:cartId/items/:productId` — Remove item `{variantId?}`
`POST /api/cart/merge` — Merge guest cart into user cart

All cart routes use optional auth; cart operations publish domain events that
feed analytics and abandonment tracking.

## Orders

`POST /api/orders` — Create an order from the current user's cart. Honors
optional `{couponCode, customerTier}` pricing context, applies pricing rules,
enforces usage caps, and **clears the cart** on success. (Authenticated)

`GET /api/orders` — User's order history (paginated: `page`, `limit`).
`GET /api/orders/:id` — Order detail (owner-only).
`PUT /api/orders/:id/status` — Update status (admin). Validates transitions and
adjusts inventory on paid/cancel. 
`POST /api/orders/:id/payment` — Attach payment info (owner-only).

Admin (group under `/api/orders/admin`):
`GET /api/orders/admin/` — All orders (paginated, optional `status` filter)
`GET /api/orders/admin/stats` — Counts by status

## Auth / Profile

All under `/api/auth` (require userbrew token):

`GET /api/auth/profile` — Profile from token claims
`PUT /api/auth/profile` — Update profile
`GET /api/auth/verify` — Validate current token
`GET /api/auth/addresses` · `POST /api/auth/addresses`
`GET /api/auth/payment-methods` · `POST /api/auth/payment-methods`
`GET /api/auth/wishlist` · `POST /api/auth/wishlist/:productId` · `DELETE /api/auth/wishlist/:productId`

## Payments

- `POST /api/payments/checkout` — Conekta hosted checkout (primary flow)
- `POST /api/payments/webhook` — Conekta webhook (signature-verified)
- `POST /api/payments/stripe-webhook` — Stripe webhook (signature-verified)
- `GET /api/payments/stripe-config` — Public Stripe config
- Stripe PaymentIntent management (retained):
  `POST /api/payments/create-payment-intent`, `POST /api/payments/confirm`,
  `POST /api/payments/cancel`, `GET /api/payments/intent/:id`,
  `POST /api/payments/simulate-success`
- `GET /payments/confirmation` · `GET /payments/cancelled` — provider redirect
  landing pages (register before `/api/*` to avoid route conflicts)

## Pricing (admin)

All under `/api/pricing`:

- `GET/POST /api/pricing/price-sets` · `PUT/DELETE /api/pricing/price-sets/:id`
- `GET/POST /api/pricing/price-schedules` · `PUT/DELETE /api/pricing/price-schedules/:id`
- `GET /api/pricing/price-history`
- `POST /api/pricing/resolve` — price resolution preview

## Analytics (admin)

`GET /api/analytics/carts/abandoned` — abandoned cart counts/value by day
`GET /api/analytics/carts/conversions` — conversions by day
`GET /api/analytics/products/views` — product views by day
`GET /api/analytics/search` — top search queries (top 20, case-normalized)

All analytics endpoints require `start` and `end` as `YYYY-MM-DD` (range ≤ 365
days). Data is collected from domain events (`cart.*`, `search.performed`,
`product.viewed`) into MongoDB.

## Images

Imgvault-backed, proxied by the backend:
`GET /api/imgvault/images/:id/file`, `GET /api/imgvault/images/:id/variant/:variant`,
`POST /api/imgvault/upload`, `GET /api/images/health`

## Error Codes

- 400 — Bad request / validation
- 401 — Unauthorized (missing/invalid token)
- 403 — Forbidden (authenticated but insufficient role)
- 404 — Not found
- 500 — Server error

## Examples

```javascript
// Search products (client sends the selected category ObjectIDs)
fetch('http://localhost:8080/api/products?q=manzana&category=64b1f2a3c4d5e6f7a8b9c0d1&sort=basePrice&order=asc')
  .then(r => r.json())
  .then(({ data }) => console.log(data));

// Create an order from the current cart (authenticated)
fetch('http://localhost:8080/api/orders', {
  method: 'POST',
  headers: { 'Authorization': 'Bearer ' + jwt, 'Content-Type': 'application/json' },
  body: JSON.stringify({ couponCode: 'BIENVENIDO10' }),
});
```