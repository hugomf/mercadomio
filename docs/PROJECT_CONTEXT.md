# Project Context

## Deployment — Shared Platform Stack (2026-09-05 plan)

Single global platform stack per environment (local, dev, qa, prod) owned by `sonnora-deploy/platform/` and deployed once per env host to the shared `infra` external docker network. Stack name `sonnora-platform-<env>`, services `userbrew-server` (8090 local / 3001 remote), `sentinel` (9000), `imgvault-server` (8081 local / 28081 remote), `minio` (9000/9001 local / 29000/29001 remote), `create-buckets` (public). All services join `networks.infra: {name: infra, external: true}`. Consumers join the same `infra` where they need service-name DNS (e.g. mercadomio backend -> `http://imgvault-server:8081`).

### Platform ownership
- Engine `deploy.sh --platform` branch: `PROJECT=platform`, `PROJECT_DIR=platform`, env from `platform/env/<env>.env`, compose from `platform/docker/docker-compose.<env>.yml`.
- VPS edge via `deploy.sh --register-vps` loop over `platform/vps/*.conf.tmpl` (generic nginx vhost, `envsubst ${DOMAIN} ${APP_HOST_IP} ${VPS_PORT}` per service `${base}_DOMAIN`/`PORT`).
- Base blueprint `platform/sentinel/self-host.<env>.yaml` creates the sole shared sentinel `sentry-<env>` (app + admin user + sentinel, no policies, deny 7200). `platform/scripts/bootstrap.sh` creates `infra` (or via ssh), waits `/health`, logs in as admin, applies blueprint, persists sole `SENTINEL_TOKEN` to `platform/env/<env>.env` on first apply (idempotent: report token null on re-apply). Wrapper `platform/deploy.sh` runs `bootstrap.sh --prepare-only` then `deploy.sh --platform --bootstrap --env <env>`.

### Consumer model
- mercadomio local: dropped bundled `userbrew`/`imgvault`/`minio`/`create-buckets` and `userbrew_data` volume from `docker/docker-compose.yml`; backend joins `[default, infra]` with `IMGVAULT_URL=http://imgvault-server:8081` over infra; local IdP remains `http://localhost:8090` via platform stack (`setup-userbrew.sh` header updated).
- mercadomio remote: `deploy/shared/docker/docker-compose.infra.yml` trimmed to app-only postgres/mongo/redis/directus (mercadomio-net unchanged); `deploy/shared/docker/docker-compose.app.yml` adds `infra` external and backend `[default, infra]`; `deploy/env/qa.env` points `IMGVAULT_URL` to `imgvault-server:8081` with shared `IMGVAULT_API_KEY`.
- rideshare: `deploy/{dev,qa,prod,local}/self-host.yaml` uses `sentinel: {ref: sentry-<env>, policies: [...]}` (policies additive per app+path); `bootstrap.sh` no longer writes `SENTINEL_TOKEN`.

### Constraints preserved
Host co-location per env (qa `sonnora-qa` 10.0.0.4), platform rides only deploy.sh layer, secrets reused from existing per-env values, git commits gated per GC11, local mirrors platform shape on same ports.

## Fragment Architecture
Modular Golang `Fragment` (Init/Execute/Shutdown), Flutter `FragmentWidgets`, `ControlPanels` for settings, `FragmentRegistry` static import. MongoDB collections products/users/orders/fragments/control_panels, Directus CMS, Redis Stack caching + Pub/Sub. See `docs/architecture.md` for full stack.
