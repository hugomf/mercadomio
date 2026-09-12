# Auth Architecture — Full Delegation to userbrew

**Status:** Design decision locked (2026-08-14). Token wiring implemented (backend OIDC validation + frontend `openid_client` flow; see `backend/services/oidc.go`, `backend/middleware/auth.go`, `frontend/lib/services/oidc_flow.dart`).

## Decision

All authentication and authorization for the MercadoMio platform is delegated to
**userbrew** (the federated identity provider at `~/Projects/userbrew`). The
MercadoMio backend becomes a pure **resource server**: it validates userbrew
tokens and authorizes based on token claims, but never mints or stores
credentials.

## Components & roles

| Component | Role | Identity source |
|---|---|---|
| userbrew | IdP / OAuth2 provider | OWNS all users, sessions, MFA, roles |
| mercadomio backend (Go Fiber, :8080) | Resource server | Validates userbrew JWT; trusts claims |
| mercadomio shop frontend (Flutter, 'Tianguis Botis') | Public OIDC client | Logs in via userbrew (PKCE) |
| admin console (Flutter) | Admin OIDC client | Logs in via userbrew (PKCE); admin RBAC |

## userbrew applications to register

Two applications (separates user populations and role scopes, matches userbrew's
per-application RBAC model):

1. **`mercadomio-shop`** — customers. `provider_type: oidc` (or social).
   redirect URI: shop app callback. Grants e.g. `customer:*`.
2. **`mercadomio-admin`** — staff. `provider_type: oidc`.
   redirect URI: admin console callback. Grants e.g. `admin:orders`,
   `admin:all`, etc.

Provision via `userbrew-cli quickstart --name ... --redirect-uri ...` which
creates the Application + OAuth client + CORS in one call. Configure
`allowed_origins` on both clients.

## Auth flows

### 1. Login (both clients)

Standard OIDC **Authorization Code + PKCE (S256)**:

1. Flutter app (using `openid_client` on pub.dev — the library listed in
   userbrew's REQUIREMENTS for Dart/Flutter) starts the flow against:
   `GET https://<idp>/.well-known/openid-configuration`
2. User authenticates at userbrew (password / social / MFA as configured on the
   application's flow).
3. userbrew redirects to the app with an auth code; app exchanges it at
   `POST /oauth/token` and stores the app-scoped JWT (carries roles/permissions
   via `generate_app_token` — deny-wins RBAC).
4. App attaches `Authorization: Bearer <jwt>` to backend requests.

### 2. Backend validation

MercadoMio's `AuthMiddleware` is rewritten to validate **userbrew** tokens only:

- **Recommended:** local signature verification against userbrew's JWKS
  (fetched from `/.well-known/openid-configuration` → `jwks_uri`), using Go
  `coreos/go-oidc` or `golang-jwt/jwt` with keyset. Zero per-request network hop.
- **Stricter alternative:** `POST /oauth/introspect` (RFC 7662) per request —
  full upstream revocation checks but adds latency + upstream dependency.

Adopt the recommended path first; keep the middleware behind an interface so
introspection can be swapped in later.

### 3. Authorization

- **Admin routes** (`/api/orders/admin`, `/stats`, future admin) require the
  `mercadomio-admin` audience/scope and an admin role claim
  (e.g. `admin:orders`) — 403 otherwise.
- **Shop routes** resolve `userID` from the JWT subject/claim. No own-session
  lookups. Wishlist etc. key off the token identity.
- Removed mercadomio-side logging in where it exists (see Backend changes).

## Backend changes (implemented)

- Vendored `AuthService` register/login removed; `JWT_SECRET` dropped from
  mercadomio; local auth endpoints (`POST /api/auth/register|login`) no longer
  exist.
- `AuthMiddleware` accepts only userbrew bearer tokens; extracts identity +
  roles into request context (`userID`, `isAdmin`). See
  `backend/services/oidc.go` (discovery/JWKS, projected-role claims) and
  `backend/middleware/auth.go`.
- Admin group (`/api/orders/admin`, product/category/pricing/analytics writes)
  guarded by `AdminMiddleware`.
- Public catalog/cart endpoints remain open or claim-resolved as before.

## Frontend changes (implemented)

- Shop app login via OIDC PKCE (`frontend/lib/services/oidc_flow.dart`,
  `openid_client`); issues userbrew tokens used as bearer on API calls.
- Admin console documents the `mercadomio-admin` audience/role for staff.

## Open items (not yet decided / deferred)

- Whether shop customers are true userbrew users (provisioned on first login) vs.
  a separate guest identity — follow userbrew's social-login auto-provision
  pattern (find-or-create by email).
- Introspection vs. local verification (recommendation above stands).
- Exact role/permission names for shop vs. admin.
- JWKS caching/TTL in the Go middleware.

## Out of scope for this doc

- Fine-grained role/permission naming beyond the two audiences.
- Any changes inside `~/Projects/userbrew` itself.