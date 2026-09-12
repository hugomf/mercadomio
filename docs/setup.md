# MercadoMío Local Development Setup

## Prerequisites

- Go toolchain, Flutter SDK
- MongoDB + Redis (or use the scripts below, which bring up Docker-dependent
  services and the platform stack)
- A running userbrew IdP (OIDC) and imgvault image service for full auth/images

> **Note:** builds in this repo use `GOROOT=` to pick up the updated Go
> toolchain — the checked-out `go` may point at an older gvm install
> (see AGENTS.md).

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your changes
4. Make your changes
5. Push to your fork and submit a pull request

## 1. Clone the Repository

```
git clone <your-repo-url>
cd mercadomio
```

## 2. Start the Stack

```
./scripts/start.sh          # dependent services + backend
./scripts/frontend.sh       # Flutter storefront
./scripts/admin-console.sh  # Flutter admin console
```

- Backend (Go/Fiber): http://localhost:8080
- Storefront (Flutter web): http://localhost:3000
- Redis (local dev): `localhost:6380` (see `backend/.env.example`)
- Admin console: served by `scripts/admin-console.sh`

The platform stack (userbrew, imgvault) is provided by the local
`platform/docker/docker-compose.local.yml`; seeds live in `seed/` (e.g.
`seed/seed_grocery.sh`, `seed/scrape-natura-api.sh` for the catalog import).

There is **no** root `docker-compose.yml` — write-in Docker runs are handled by
the `scripts/` helpers and `platform/`.

## 3. Backend Configuration

```
cd backend
cp .env.example .env
```

Key variables: `MONGO_URI`, `REDIS_ADDR`, `USERBREW_ISSUER`/`DISCOVERY_URL`/`
AUDIENCES`, `IMGVAULT_URL`/`IMGVAULT_API_KEY`, `CONEKTA_SECRET_KEY`,
`CONEKTA_WEBHOOK_PUBLIC_KEY_PEM`. Either copy `.env.example` or let
`scripts/start.sh` load `backend/local.env`.

## 4. MongoDB

- MongoDB is available at `mongodb://localhost:27017/mercadomio`
- Use MongoDB Compass (or `mongosh`) for management.

## 5. Development

- Backend code: `/backend`
- Storefront code: `/frontend`
- Admin console: `/admin_console`
- Docs: `/docs`

## 6. API Smoke Tests

```bash
curl "http://localhost:8080/api/products?sort=basePrice&order=asc"
curl "http://localhost:8080/api/products?sort=createdAt&order=desc"
curl "http://localhost:8080/api/categories"
```

Storefront and admin requests include `Authorization: Bearer <userbrew JWT>`
once logged in via OIDC.

## 7. Stopping Services

Stop the Docker-dependent services with `./scripts/stop.sh` or
`./scripts/local-stop.sh`, then stop the Flutter/Go processes you launched.
There is no single root `docker-compose down` anymore.
