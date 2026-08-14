# Auth Architecture — Full Delegation to userbrew

**Status:** Design decision locked (2026-08-14). Token wiring NOT yet implemented.

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

## Backend changes (planned)

- Delete/deprecate vendored `AuthService` (register/login/validate) and
  `JWT_SECRET` from mercadomio; credential-free users collection no longer
  authoritative for auth.
- `AuthMiddleware`: accept only userbrew bearer tokens; extract identity + roles
  into request context (`userID`, `roles`).
- Remove the hardcoded `userID` shortcut in admin handlers; rely on claims.
- Guard admin group with role check.
- Keep the public catalog/cart endpoints open or claim-resolved as today.

## Frontend changes (planned)

- Shop app `AuthService` replaced by `openid_client` OIDC session (userbrew).
- Admin console `AdminOrderService` gains a real login flow: OIDC → token →
  `Authorization` header (currently sends none).
- Token storage + refresh via `openid_client`/secure storage.

## Open items (not yet decided / deferred)

- Whether shop customers are true userbrew users (provisioned on first login) vs.
  a separate guest identity — follow userbrew's social-login auto-provision
  pattern (find-or-create by email).
- Introspection vs. local verification (recommendation above stands).
- Exact role/permission names for shop vs. admin.
- JWKS caching/TTL in the Go middleware.

## Out of scope for this doc

- Token wiring implementation (deferred by owner).
- Any changes inside `~/Projects/userbrew` itself.