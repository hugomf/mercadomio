# Shared Platform Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure deployments so each environment (local, dev, qa, prod) shares ONE global platform stack — one userbrew IdP, one shared sentinel edge proxy, and shared services (imgvault+minio now, credentialvault later) — owned by a new `platform/` subtree in sonnora-deploy, with all consumer apps joining the shared `infra` network and never bundling their own userbrew.

**Architecture:** sonnora-deploy gains a `--platform` engine branch; its `platform/` subtree owns one parameterized docker stack per env (userbrew-server + sentinel + imgvault + minio + create-buckets) deployed once to each env host via the existing deploy.sh pipeline. A platform `scripts/bootstrap.sh` prepares the external `infra` network, applies a per-env base blueprint that FINDS-OR-CREATES the single shared sentinel (`sentry-<env>`), and persists the single `SENTINEL_TOKEN`. Consumer apps (mercadomio, rideshare) drop their per-app userbrew wiring, join `infra` where they need internal service-name access (imgvault), and append their own named sentinel policies onto the shared sentinel via blueprint `ref`.

**Tech Stack:** bash (deploy.sh engine + bootstrap scripts), docker compose (external `infra` network), nginx (VPS edge templates + certbot), userbrew blueprint YAML (global.app / users / sentinel), Go+Flutter (mercadomio), Rust (rideshare).

**Spec:** No standalone spec document (not requested). The design was approved in session and its decisions are captured verbatim in **Global Constraints** below. Related existing specs, which the plan must remain consistent with:
- `docs/superpowers/specs/2026-08-21-userbrew-oidc-design.md`
- `docs/superpowers/specs/2026-08-29-multienv-deploy-directus-imgvault-design.md`
- `docs/superpowers/specs/2026-09-05-product-images-imgvault-design.md`

## Global Constraints

These are the approved design decisions. Every task's requirements implicitly include this section. The executor must NOT deviate without asking the user.

1. **One shared sentinel per environment** ("one for all of them for now for simplicity"). Named `sentry-<env>` (e.g. `sentry-qa`). Name created by the platform base blueprint; consumers reference it via `sentinel: { ref: sentry-<env>, policies: [...] }`.
2. **Platform owns the ONLY `SENTINEL_TOKEN`**. It is persisted to `platform/env/<env>.env` by `scripts/bootstrap.sh` on first apply. No per-app sentinel tokens anywhere. Consumer apps neither create sentinels nor write sentinel tokens.
3. **Consumer apps must NOT bundle userbrew.** mercadomio's local sidecar (`docker/docker-compose.yml` userbrew service + `userbrew_data` volume) is removed entirely. rideshare already has no local userbrew.
4. **Shared stack is deployed once per env to the env host.** Stack name `sonnora-platform-<env>`. All services join the external `infra` network (`networks: { infra: { name: infra, external: true } }`).
5. **App-level stateful infra stays per-app.** mercadomio keeps its own postgres/mongo/redis/directus. Only userbrew, sentinel, imgvault, minio (and future credentialvault) become platform-owned.
6. **Engine boundary:** the platform stack rides ONLY the deploy.sh layer (stage env+compose → pull → up → wait_health → register-vps). The ansible `playbooks/`, `roles/`, `inventory/`, `deploy-users/` layer is NEVER invoked by the platform path.
7. **Co-location assumption (per env):** platform stack + consumer app stacks run on the SAME host (qa: `sonnora-qa`, `APP_HOST_IP=10.0.0.4`), so the shared `infra` network + service-name DNS work. Cross-host is out of scope; flipping env URLs to public domains is config-only if ever needed.
8. **Local env mirrors platform shape.** Local platform stack is run from `platform/docker` directly (`docker compose -f docker-compose.local.yml up -d`), NOT via deploy.sh. Local ports stay backward-compatible: userbrew `8090`/`5174`, imgvault `8081`, minio `9000`. mercadomio local joins `infra`; `scripts/setup-userbrew.sh --env local` keeps defaulting to `http://localhost:8090`.
9. **Edge via existing `--register-vps` mechanism.** Platform services get VPS nginx conf templates in `platform/vps/<env>/<service>.conf.tmpl`, rendered with `envsubst` over `\${DOMAIN} \${APP_HOST_IP} \${VPS_PORT}` (per-service DOMAIN/PORT from the env file), each registered via `vps_register` with `conf_name <service>-<env>`. Per-service domains must already resolve to `VPS_HOST` (DNS prep, infra task). Do NOT use `${VPS_UPSTREAM}` (known pre-existing engine quirk — userbrew compose leaves it literal).
10. **New shared service onboarding rule:** publish image → 1 compose service block → 1 vps tmpl → 1 env entry. credentialvault stays FUTURE (not in this plan).
11. **Git:** per AGENTS.md + user-level rule, NO git commands (add/commit/checkout/... ) without explicit user approval. Commit steps below are conditional: ask the user first.
12. **Secrets:** reuse existing per-env values already committed in repos (dev defaults like `dev_api_key_123`, `minioadmin` are the existing convention). Never invent/commit NEW prod secrets; prod values come from the existing userbrew deploy `.env.prod`. Bump `IMGVAULT_PORT`/`IMGVAULT_URL` consumer wiring to platform vars on merging.
13. **Verification discipline:** do not claim success without running the command listed in the step and seeing its output. Run shellcheck on every new/edited bash script.
14. **Repos and canonical paths:**
    - `/Users/hugo/Projects/sonnora-deploy` — engine (deploy.sh, lib/common.sh) + new `platform/`
    - `/Users/hugo/Projects/mercadomio` — consumer + setup script + session docs
    - `/Users/hugo/Projects/rideshare` — consumer
    - `/Users/hugo/Projects/userbrew` — READ-ONLY reference for service env blocks + blueprint semantics

---

## File Structure

### sonnora-deploy (engine + platform)
| File | Responsibility |
|---|---|
| `deploy.sh` (modify) | gains `--platform` branch: PROJECT_DIR→platform, env/compose defaults, register-vps loop |
| `lib/common.sh` (unchanged; used) | `vps_register`, `remote_*`, `wait_health`, `gitea_login` |
| `platform/env/<env>.env` (create ×4) | all per-env vars (host, ports, URLs, versions, secrets, per-service DOMAIN/PORT) |
| `platform/docker/docker-compose.<env>.yml` (create ×4) | shared stack for that env; `infra` external network |
| `platform/sentinel/self-host.<env>.yaml` (create ×4) | base blueprint: platform app + admin user + `sentry-<env>` sentinel (NO policies) |
| `platform/scripts/bootstrap.sh` (create) | `--prepare` (create `infra` on host, local or via ssh), then apply base blueprint, persist SENTINEL_TOKEN; idempotent |
| `platform/deploy.sh` (create) | thin wrapper: `bootstrap.sh --prepare` then `../deploy.sh --platform --bootstrap --env <env>` |
| `platform/vps/<env>/<service>.conf.tmpl` (create) | nginx vhost template per platform service per env (userbrew, sentinel, imgvault) |

### mercadomio (consumer)
| File | Responsibility |
|---|---|
| `docker/docker-compose.yml` (modify) | remove userbrew sidecar block + `userbrew_data` volume; remove imgvault/minio/create-buckets; join `infra`; backend imgvault env → `imgvault-server` |
| `docker/.env` / `.env.local` (check only) | OAuth redirects unchanged (8090/5174 still valid) |
| `scripts/setup-userbrew.sh` (modify, minor) | keep defaults; header comment updated to say local targets the local platform stack |
| `deploy/shared/docker/docker-compose.infra.yml` (modify) | drop imgvault/minio/create-buckets (postgres/mongo/redis/directus stay) |
| `deploy/shared/docker/docker-compose.app.yml` (modify) | add `infra` external network to backend |
| `deploy/env/qa.env` (modify) | `IMGVAULT_URL=http://imgvault-server:8081`; `IMGVAULT_API_KEY` from platform |

### rideshare (consumer)
| File | Responsibility |
|---|---|
| `deploy/qa/bootstrap.sh` etc. (modify) | delete the SENTINEL_TOKEN write block (report parsing keeps sentinel_id) |
| `deploy/{dev,qa,prod,local}/self-host.yaml` (modify ×4) | `global.sentinel` → `ref: sentry-<env>` (keep own policies) |

### userbrew — READ-ONLY
Source of truth for the server/sentinel env blocks (`deploy/qa/docker-compose.qa.yml`) and blueprint `sentinel` semantics (`crates/userbrew-blueprint/src/engine.rs`): sentinel refs are ADDITIVE — policies reconcile per `application_id + path`, so many apps append onto one shared sentinel. No userbrew file changes.

---

## Task 1: Engine — `--platform` argument and project/env/compose redirection

**Files:**
- Modify: `/Users/hugo/Projects/sonnora-deploy/deploy.sh`

**Interfaces:**
- Consumes: existing flag parse loop (~lines 58-70, pattern is `--project) PROJECT="$2"`), PROJECT_DIR resolution (~lines 75-88), COMPOSE_FILES default (~line 142).
- Produces: when `PLATFORM=1` → `PROJECT=platform`, `PROJECT_DIR="$SCRIPT_DIR/platform"`, env sourced from `"$PROJECT_DIR/env/$ENV.env"`, `COMPOSE_DIR` defaults to `"$PROJECT_DIR/docker"`, `COMPOSE_FILES` defaults to `"$COMPOSE_DIR/docker-compose.$ENV.yml"`.

- [ ] **Step 1: Add the flag**

In the argument parse loop add a new case (matches existing `--bootstrap` style boolean flags):

```bash
    --platform) PLATFORM=1 ;;
```

- [ ] **Step 2: Redirect project resolution when `--platform`**

Right after `PROJECT_DIR` is set (and before the `PROJECT_DIR` existence check):

```bash
if [ -n "$PLATFORM" ]; then
  PROJECT="platform"
  PROJECT_DIR="$SCRIPT_DIR/platform"
fi
```

- [ ] **Step 3: Redirect env file source**

The existing source line uses `ENV_FILE="$PROJECT_DIR/deploy/env/$ENV.env"`. Change to:

```bash
if [ -n "$PLATFORM" ]; then
  ENV_FILE="$PROJECT_DIR/env/$ENV.env"
else
  ENV_FILE="$PROJECT_DIR/deploy/env/$ENV.env"
fi
```

- [ ] **Step 4: Redirect compose defaults**

Where `COMPOSE_DIR`/`COMPOSE_FILES` defaults are computed:

```bash
if [ -n "$PLATFORM" ]; then
  COMPOSE_DIR="${COMPOSE_DIR:-$PROJECT_DIR/docker}"
  COMPOSE_FILES="${COMPOSE_FILES:-$COMPOSE_DIR/docker-compose.$ENV.yml}"
fi
```

- [ ] **Step 5: Dry-run verify (requires a platform env file to exist — create `platform/env/qa.env` in Task 3 first, or run this after Task 3)**

Run: `./deploy.sh --platform --env qa --dry-run` (from `sonnora-deploy`)
Expected: proceeds past env source; logs platform paths, e.g. `Using project dir: /Users/hugo/Projects/sonnora-deploy/platform`, composes list `.../platform/docker/docker-compose.qa.yml`. No `deploy/env/qa.env` error.

- [ ] **Step 6: shellcheck + non-platform regression**

Run: `shellcheck deploy.sh`
Expected: no errors (existing warnings acceptable if pre-existing).
Run: `./deploy.sh --project mercadomio --env qa --dry-run`
Expected: unchanged behavior — resolves mercadomio normally (this may fail at DNS/ssh checks; the point is it routes to `$PROJECTS_ROOT/mercadomio`, NOT platform).

- [ ] **Step 7: Commit (after user approval per Global Constraint 11)**

```bash
git add deploy.sh
git commit -m "feat(deploy): add --platform branch for shared platform stacks"
```

---

## Task 2: Engine — `--register-vps` loop over platform service templates

**Files:**
- Modify: `/Users/hugo/Projects/sonnora-deploy/deploy.sh`

**Interfaces:**
- Consumes: Task 1 (`PLATFORM=1`), existing register-vps block (~lines 237-260), `lib/common.sh: vps_register`.
- Produces: when `PLATFORM=1` and `--register-vps`, iterates `"$PROJECT_DIR"/vps/"$ENV"/*.conf.tmpl`, per template reads `${base}_DOMAIN` and `${base}_PORT` from the sourced env, renders with `envsubst '${DOMAIN} ${APP_HOST_IP} ${VPS_PORT}'`, registers with `conf_name "$base-$ENV"`.

- [ ] **Step 1: Branch the existing register-vps block**

Wrap the existing single-template logic and prepend the platform loop:

```bash
if [ -n "$REGISTER" ]; then
  if [ -n "$PLATFORM" ]; then
    for tmpl in "$PROJECT_DIR"/vps/"$ENV"/*.conf.tmpl; do
      base="$(basename "$tmpl" .conf.tmpl)"
      DOMAIN="$(eval "printf '%s' \"\${${base}_DOMAIN:-}\"")"
      VPS_PORT="$(eval "printf '%s' \"\${${base}_PORT:-}\"")"
      [ -n "$DOMAIN" ] || die "platform vps: \$${base}_DOMAIN unset in $ENV_FILE"
      [ -n "$VPS_PORT" ] || die "platform vps: \$${base}_PORT unset in $ENV_FILE"
      local_tmp="${TMP_DIR:-/tmp}/$base-$ENV.conf"
      envsubst '${DOMAIN} ${APP_HOST_IP} ${VPS_PORT}' < "$tmpl" > "$local_tmp"
      vps_register "$local_tmp" "$base-$ENV" "${EXTRA_DIRS:-}"
    done
  else
    # ... existing single-template register-vps code unchanged ...
  fi
fi
```

- [ ] **Step 2: Static check**

Run: `bash -n deploy.sh && shellcheck deploy.sh`
Expected: syntax OK, no new shellcheck errors.

- [ ] **Step 3: Render smoke test (needs a tmpl — create `platform/vps/qa/userbrew.conf.tmpl` in Task 8, or run after Task 8)**

```bash
set -a; source platform/env/qa.env; set +a
DOMAIN="$USERBREW_DOMAIN" VPS_PORT="$USERBREW_SERVER_PORT" \
  envsubst '${DOMAIN} ${APP_HOST_IP} ${VPS_PORT}' < platform/vps/qa/userbrew.conf.tmpl
```

Expected: output with NO remaining `${` tokens; `server_name userbrew.qa.sonnora.mx;` and `proxy_pass http://10.0.0.4:3001;`.

- [ ] **Step 4: Commit (after user approval)**

```bash
git add deploy.sh
git commit -m "feat(deploy): register-vps loop over platform service templates"
```

---

## Task 3: Platform env files (one per environment)

**Files:**
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/env/local.env`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/env/dev.env`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/env/qa.env`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/env/prod.env`

**Interfaces:**
- Consumes: Task 1/2 var contract (`APP_HOST`, `DOMAIN`, `APP_HOST_IP`, `APP_DIR`, `REGISTRY_IMAGE_TAG`, `${base}_DOMAIN`, `${base}_PORT`, `HEALTH_PORT`, `HEALTH_PATH`).
- Produces: the single source of truth for every platform var; `SENTINEL_TOKEN=` empty until Task 6 fills it; consumed by Tasks 4, 5, 8.

- [ ] **Step 1: Write `platform/env/qa.env`** (mirror rideshare/mercadomio qa host values from `mercadomio/deploy/env/qa.env`):

```bash
# platform stack - qa (host: sonnora-qa)
APP_HOST=sonnora-qa
VPS_HOST=sonnora
APP_HOST_IP=10.0.0.4
APP_DIR=/opt/platform
DOMAIN=userbrew.qa.sonnora.mx
REGISTRY_IMAGE_TAG=qa
HEALTH_PORT=3001
HEALTH_PATH=/health

REGISTRY=gitea.sonnora.mx
OWNER=sonnora-mx
IMAGE_USERBREW=userbrew/userbrew
USERBREW_VERSION=latest
USERBREW_SERVER_PORT=3001
USERBREW_UI_PORT=5173
USERBREW_PUBLIC_URL=https://userbrew.qa.sonnora.mx
JWT_ISSUER=userbrew-qa
JWT_SECRET=change-me-qa-jwt
PEPPER=change-me-qa-pepper
TOKEN_SECRET=change-me-qa-token
USERBREW_ADMIN_EMAIL=admin@sonnora.mx
USERBREW_ADMIN_USERNAME=platform-admin
USERBREW_ADMIN_PASSWORD=change-me-qa-admin

IMAGE_SENTINEL=userbrew/sentinel
SENTINEL_VERSION=latest
SENTINEL_PORT=9000
SENTINEL_TOKEN=

IMAGE_IMGVAULT=mercadomio/imgvault
IMGVAULT_VERSION=qa
IMGVAULT_PORT=28081
IMGVAULT_API_KEY="REDACTED"
MINIO_PORT=29000
MINIO_CONSOLE_PORT=29001
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

USERBREW_DOMAIN=userbrew.qa.sonnora.mx
SENTINEL_DOMAIN=sentinel.qa.sonnora.mx
IMGVAULT_DOMAIN=imgvault.qa.sonnora.mx
```

- [ ] **Step 2: Write the other three env files**

Same shape. `local.env` overrides: `APP_HOST=localhost`, `USERBREW_SERVER_PORT=8090`, `USERBREW_UI_PORT=5174`, `USERBREW_PUBLIC_URL=http://localhost:8090`, `IMGVAULT_PORT=8081`, `MINIO_PORT=9000`/`9001`, `JWT_ISSUER=userbrew-local`, `USERBREW_ADMIN_USERNAME=mercadomio-admin` (matches the old sidecar so OAuth/console state stays recognizable), `USERBREW_DOMAIN`/`SENTINEL_DOMAIN`/`IMGVAULT_DOMAIN` empty or `localhost` variants (unused: no VPS for local). `dev.env`: `APP_HOST=sonnora-dev`, host/ports mirror qa pattern, `USERBREW_PUBLIC_URL=https://userbrew.dev.sonnora.mx`, `JWT_ISSUER=userbrew-dev`. `prod.env`: `APP_HOST=sonnora`, `USERBREW_PUBLIC_URL=https://userbrew.sonnora.mx`, `JWT_ISSUER=userbrew-prod`, real secret values sourced from `/Users/hugo/Projects/userbrew/deploy/.env.prod` (copy values, do not invent).

- [ ] **Step 3: Verify all four source cleanly**

Run: 
```bash
for e in local dev qa prod; do set -a; . "platform/env/$e.env"; set +a; echo "$e ok: $USERBREW_PUBLIC_URL / $USERBREW_SERVER_PORT"; done
```
Expected: four `ok` lines, correct URL/port per env (local 8090, qa 3001, etc.).

- [ ] **Step 4: Commit (after user approval)**

```bash
git add platform/env/
git commit -m "feat(platform): per-env platform stack configuration"
```

---

## Task 4: Platform docker compose files

**Files:**
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/docker/docker-compose.local.yml`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/docker/docker-compose.dev.yml`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/docker/docker-compose.qa.yml`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/docker/docker-compose.prod.yml`

**Interfaces:**
- Consumes: Task 3 env vars (all `${VAR}` interpolations below come from the env file).
- Produces: the shared stack for each env. Service names inside `infra` are `userbrew-server`, `sentinel`, `minio`, `imgvault-server` (these exact names are the DNS consumers rely on, and `imgvault-server` is referenced by mercadomio in Task 10).

- [ ] **Step 1: Write `docker-compose.qa.yml`** (single source, env-differentiated — copy to the other envs changing only the `name:` suffix; the local/ dev/ prod/ files are the same body because all differences live in env files):

```yaml
name: sonnora-platform-qa

networks:
  infra:
    name: infra
    external: true

volumes:
  idp_data:
  minio_data:

services:
  userbrew-server:
    image: ${REGISTRY:?}/${OWNER:?}/${IMAGE_USERBREW:?}:${USERBREW_VERSION:-latest}
    container_name: platform-userbrew-qa
    restart: unless-stopped
    ports:
      - "${USERBREW_SERVER_PORT:-3001}:3000"
      - "${USERBREW_UI_PORT:-5173}:5173"
    volumes:
      - idp_data:/data
    environment:
      DATABASE_URL: sqlite:///data/idp.db?mode=rwc
      HOST: "0.0.0.0"
      PORT: "3000"
      PUBLIC_URL: ${USERBREW_PUBLIC_URL:?}
      JWT_ISSUER: ${JWT_ISSUER:?}
      JWT_SECRET: ${JWT_SECRET:?}
      PEPPER: ${PEPPER:?}
      TOKEN_SECRET: ${TOKEN_SECRET:?}
      MAILER_ADAPTER: stub
      SMTP_HOST: ${SMTP_HOST:-localhost}
      SMTP_PORT: ${SMTP_PORT:-1025}
      SMTP_USERNAME: ${SMTP_USERNAME:-}
      SMTP_PASSWORD: ${SMTP_PASSWORD:-}
      SMTP_USE_TLS: ${SMTP_USE_TLS:-false}
      SMTP_FROM: ${SMTP_FROM:-noreply@sonnora.mx}
      SMTP_REPLY_TO: ${SMTP_REPLY_TO:-noreply@sonnora.mx}
      WEBAUTHN_ORIGIN: ${USERBREW_PUBLIC_URL:?}
      OAUTH_ENABLED: "false"
      RUST_LOG: server=info,tower_http=info
      BACKEND_URL: http://localhost:3000
      USERBREW_BOOTSTRAP: "1"
      USERBREW_ADMIN_EMAIL: ${USERBREW_ADMIN_EMAIL:?}
      USERBREW_ADMIN_USERNAME: ${USERBREW_ADMIN_USERNAME:?}
      USERBREW_ADMIN_PASSWORD: ${USERBREW_ADMIN_PASSWORD:?}
      USERBREW_BASE_URL: ${USERBREW_PUBLIC_URL}
      USERBREW_JWT_ALGORITHM: HS256
      USERBREW_GENERATE_RSA_KEYS: "false"
    healthcheck:
      test: ["CMD", "bun", "fetch", "http://localhost:3000/health"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 20s
    networks:
      - infra

  sentinel:
    image: ${REGISTRY:?}/${OWNER:?}/${IMAGE_SENTINEL:?}:${SENTINEL_VERSION:-latest}
    container_name: platform-sentinel-qa
    restart: unless-stopped
    ports:
      - "${SENTINEL_PORT:-9000}:9000"
    environment:
      USERBREW_URL: http://userbrew-server:3000
      SENTINEL_TOKEN: ${SENTINEL_TOKEN:?}
      LISTEN_ADDR: 0.0.0.0:9000
      SENTINEL_MODE: proxy
      RUST_LOG: sentinel=info
    depends_on:
      userbrew-server:
        condition: service_healthy
    networks:
      - infra

  minio:
    image: minio/minio:latest
    container_name: platform-minio-qa
    restart: unless-stopped
    command: server /data --console-address ":9001"
    ports:
      - "${MINIO_PORT:-29000}:9000"
      - "${MINIO_CONSOLE_PORT:-29001}:9001"
    volumes:
      - minio_data:/data
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-minioadmin}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minioadmin}
    networks:
      - infra

  imgvault-server:
    image: ${REGISTRY:?}/${OWNER:?}/${IMAGE_IMGVAULT:?}:${IMGVAULT_VERSION:-latest}
    container_name: platform-imgvault-qa
    restart: unless-stopped
    ports:
      - "${IMGVAULT_PORT:-28081}:8081"
    environment:
      OBJECT_STORAGE_ENDPOINT: minio:9000
      OBJECT_STORAGE_EXTERNAL_ENDPOINT: 127.0.0.1:${MINIO_PORT:-29000}
      API_KEY: ${IMGVAULT_API_KEY:?}
      RUST_LOG: imgvault=info
    depends_on:
      - minio
    networks:
      - infra

  create-buckets:
    image: minio/mc:latest
    container_name: platform-buckets-qa
    restart: "no"
    entrypoint: >
      /bin/sh -c "
      mc alias set local http://minio:9000 ${MINIO_ROOT_USER:-minioadmin} ${MINIO_ROOT_PASSWORD:-minioadmin} &&
      mc mb --ignore-existing local/public &&
      exit 0
      "
    depends_on:
      - minio
    networks:
      - infra
```

- [ ] **Step 2: Create the other three env compose files**

Copy the body verbatim; change only `name:` to `sonnora-platform-local|dev|prod`. (Container names `container_name:` stay unique per env because each env file is only ever deployed on its own host — keep `platform-userbrew-qa` etc. per file.)

- [ ] **Step 3: Validate all four with compose config**

Run:
```bash
for e in local dev qa prod; do set -a; . "platform/env/$e.env"; set +a; docker compose -f "platform/docker/docker-compose.$e.yml" config --quiet && echo "$e config OK"; done
```
Expected: `qa` and `dev`/`prod` pass (requires `SENTINEL_TOKEN` non-empty via the `:?`: run with `SENTINEL_TOKEN=dummy` for the check, OR the validation may substitute from env which has empty token — if `<SENTINEL_TOKEN var is required>` errors appear, export `SENTINEL_TOKEN=check` on the command line for validation only). `local` similar. Expected: `config OK` ×4.

- [ ] **Step 4: Commit (after user approval)**

```bash
git add platform/docker/
git commit -m "feat(platform): shared stack compose (userbrew, sentinel, imgvault, minio)"
```

---

## Task 5: Platform base blueprints (per env)

**Files:**
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/sentinel/self-host.local.yaml`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/sentinel/self-host.dev.yaml`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/sentinel/self-host.qa.yaml`
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/sentinel/self-host.prod.yaml`

**Interfaces:**
- Consumes: Task 3 vars (`USERBREW_ADMIN_USERNAME/PASSWORD`, `USERBREW_PUBLIC_URL`) at apply time (bootstrap renders `\${...}` from env into the YAML before POSTing).
- Produces: creates the platform app entity and the SINGLE shared `sentry-<env>` sentinel. This is the only place the sentinel token is issued; Task 6 captures it.

- [ ] **Step 1: Write `sentinel/self-host.qa.yaml`** (base blueprint — NO sentinel policies, that is deliberate):

```yaml
global:
  console:
    enabled: true
    application_id: ""
  app:
    name: sonnora-platform
    launch_url: ${USERBREW_PUBLIC_URL}
    provider_type: password
    visibility: assigned
    registration_enabled: false
    flow: default-authentication-flow
  users:
    - username: ${USERBREW_ADMIN_USERNAME}
      password: ${USERBREW_ADMIN_PASSWORD}
      roles:
        - admin
  sentinel:
    name: sentry-qa
    default_action: deny
    ttl: 7200
```

Notes for the executor:
- `global.app` is required before `global.sentinel` so the sentinel attaches to `sonnora-platform` (blueprint engine: `ensure_sentinel` records `app_id` from the active app context; policies absent → no per-path rules; the shared sentinel starts EMPTY of policies).
- `global.console: enabled` mirrors rideshare's bootstrap (console UI). If the engine rejects an unknown `global.console` key, drop that block — verified against rideshare `deploy/qa/self-host.yaml`, which includes `global.console`? No — rideshare's self-host.yaml uses `global.app`/`global.users`/`global.sentinel`/`global.api_keys`; the console binding is done via a separate `PUT /admin/settings/console` call in its bootstrap.sh. Do the same: keep this YAML to `app/users/sentinel` only.

- [ ] **Step 2: Write the other three envs**

Copy verbatim; change only the sentinel `name:` → `sentry-local|dev|prod`.

- [ ] **Step 3: YAML lint + interpolate check**

Run:
```bash
python3 -c "import yaml,sys; [yaml.safe_load(open(f'platform/sentinel/self-host.{e}.yaml')) for e in ['local','dev','qa','prod']]; print('yaml OK')"
set -a; . platform/env/qa.env; set +a
sed -E 's/\$\{([A-Z_]+)\}/\1/' platform/sentinel/self-host.qa.yaml > /tmp/shh.ok && grep -c sentry-qa /tmp/shh.ok
```
Expected: `yaml OK`; the interpolated copy keeps `sentry-qa`.

- [ ] **Step 4: Commit (after user approval)**

```bash
git add platform/sentinel/
git commit -m "feat(platform): base blueprints creating shared named sentinel per env"
```

---

## Task 6: Platform bootstrap script

**Files:**
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/scripts/bootstrap.sh`

**Interfaces:**
- Consumes: Task 3 env, Task 5 blueprints, userbrew admin auth flow (same as mercadomio `scripts/setup-userbrew.sh` login), userbrew blueprint API `POST /admin/blueprints/apply` (same as rideshare bootstrap.sh).
- Produces: (a) `infra` network created on target host; (b) on `--prepare` only exits; otherwise waits `/health`, logs in as admin, applies the base blueprint, extracts `sentinel_id`/`sentinel_token` from the report, persists `SENTINEL_TOKEN` into the env file. Idempotent: on re-apply the sentinel already exists by name → report token is null → env file left unchanged.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(dirname "$SCRIPT_DIR")"

ENV=""
PREPARE_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --env) ENV="$2"; shift 2 ;;
    --env=*) ENV="${1#*=}"; shift ;;
    --prepare-only) PREPARE_ONLY=1; shift ;;
    *) echo "usage: $0 --env <local|dev|qa|prod> [--prepare-only]"; exit 1 ;;
  esac
done
[ -n "$ENV" ] || { echo "missing --env"; exit 1; }

set -a
# shellcheck disable=SC1091
. "$PLATFORM_DIR/env/$ENV.env"
set +a

remote() { # run <cmd...> locally for local, over ssh for remote envs
  if [ "$ENV" = "local" ] || [ "$ENV" = "dev" ] && [ "$APP_HOST" = "localhost" ]; then
    "$@"
  else
    ssh "${SSH_ARGS[@]:- -o ConnectTimeout=10 -o BatchMode=yes}" "${REMOTE_USER:-hugomf}@$APP_HOST" "$@"
  fi
}

# (a) infra network
if [ "$(remote docker network ls --format '{{.Name}}' 2>/dev/null)" != "infra" ]; then
  remote docker network create infra
fi
[ "$PREPARE_ONLY" = "1" ] && { echo "platform: infra network ready on $APP_HOST"; exit 0; }

# (b) wait for userbrew health
for i in $(seq 1 60); do
  if curl -fsS --max-time 5 "http://${APP_HOST}:${USERBREW_SERVER_PORT}/health" >/dev/null 2>&1; then
    break
  fi
  [ "$i" = "60" ] && { echo "userbrew not healthy after 60s"; exit 1; }
  sleep 2
done

# (c) admin auth (mirrors mercadomio scripts/setup-userbrew.sh logic)
AUTH_HEADER()
{
  if [ -n "${USERBREW_ADMIN_TOKEN:-}" ]; then
    case "$USERBREW_ADMIN_TOKEN" in
      ub_sk_*) printf 'X-API-Key: %s' "$USERBREW_ADMIN_TOKEN" ;;
      *) printf 'Authorization: Bearer %s' "$USERBREW_ADMIN_TOKEN" ;;
    esac
    return
  fi
  local setup_id login
  setup_id="$(curl -fsS -X POST "http://${APP_HOST}:${USERBREW_SERVER_PORT}/setup/console-app" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${USERBREW_ADMIN_EMAIL}\"}" | python3 -c 'import sys,json;print(json.load(sys.stdin)["application_id"])')"
  login="$(curl -fsS -X POST "http://${APP_HOST}:${USERBREW_SERVER_PORT}/auth/login" \
    -H 'Content-Type: application/json' \
    -H "X-Application-Id: $setup_id" \
    -d "{\"username\":\"${USERBREW_ADMIN_USERNAME}\",\"password\":\"${USERBREW_ADMIN_PASSWORD}\"}" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')"
  printf 'Authorization: Bearer %s' "$login"
}

# (d) render + apply base blueprint
AUTH="$(AUTH_HEADER)"
RENDERED="$(sed -E 's/\$\{([A-Z_]+)\}/\1/; s#\$\{USERBREW_PUBLIC_URL\}#'"$USERBREW_PUBLIC_URL"'#g; s#\$\{USERBREW_ADMIN_USERNAME\}#'"$USERBREW_ADMIN_USERNAME"'#g; s#\$\{USERBREW_ADMIN_PASSWORD\}#'"$USERBREW_ADMIN_PASSWORD"'#g' \
  "$PLATFORM_DIR/sentinel/self-host.$ENV.yaml")"

REPORT="$(curl -fsS -X POST "http://${APP_HOST}:${USERBREW_SERVER_PORT}/admin/blueprints/apply" \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d "$(python3 -c 'import json,sys;print(json.dumps({"yaml":sys.argv[1]}))' "$RENDERED")")"

echo "$REPORT" | python3 -c '
import sys, json
r = json.load(sys.stdin)
print("sentinel_id:", r.get("sentinel_id"))
print("sentinel_token:", "<present>" if r.get("sentinel_token") else "<null>")
for u in r.get("created_users", []):
    print("created_user:", u)
'

# (e) persist SENTINEL_TOKEN on first apply only
TOKEN="$(echo "$REPORT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("sentinel_token") or "")')"
ENV_FILE="$PLATFORM_DIR/env/$ENV.env"
if [ -n "$TOKEN" ]; then
  if grep -q '^SENTINEL_TOKEN=' "$ENV_FILE"; then
    sed -i.bak "s#^SENTINEL_TOKEN=.*#SENTINEL_TOKEN=$TOKEN#" "$ENV_FILE" && rm -f "$ENV_FILE.bak"
  else
    echo "SENTINEL_TOKEN=$TOKEN" >> "$ENV_FILE"
  fi
  echo "platform: persisted SENTINEL_TOKEN to $ENV_FILE"
fi
```

- [ ] **Step 2: Local smoke (runs against the local platform stack from Task 4)**

Run: `./platform/scripts/bootstrap.sh --env local --prepare-only`
Expected: `infra network ready on localhost` (run twice → idempotent: second run prints the same without error).
Then (once the local platform stack from Task 4 is `up`): `./platform/scripts/bootstrap.sh --env local`
Expected: first run prints `sentinel_token: <present>` and persists `SENTINEL_TOKEN=...` into `platform/env/local.env`. Second run prints `sentinel_token: <null>` and does NOT re-write the file (mtime unchanged).

- [ ] **Step 3: shellcheck + bash -n**

Run: `bash -n platform/scripts/bootstrap.sh && shellcheck platform/scripts/bootstrap.sh`
Expected: no output/syntax errors (suppress env-var-scope warnings with `# shellcheck disable` if needed).

- [ ] **Step 4: Commit (after user approval)**

```bash
git add platform/scripts/bootstrap.sh
git commit -m "feat(platform): bootstrap - infra network, shared sentinel creation, token capture"
```

---

## Task 7: Platform deploy wrapper

**Files:**
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/deploy.sh`

**Interfaces:**
- Consumes: Task 6 (`bootstrap.sh --env ENV --prepare-only`), Task 1/2 engine (`--platform`, `--bootstrap`).
- Produces: single entrypoint: `./platform/deploy.sh --env <env> [--register-vps] [--dry-run] ...` → guarantees infra network exists before compose up, then runs the full engine pipeline including the post-up bootstrap.

- [ ] **Step 1: Write the wrapper**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[s -x "$SCRIPT_DIR/scripts/bootstrap.sh" ]     # gate on missing? instead:
[ -f "$SCRIPT_DIR/scripts/bootstrap.sh" ] || { echo "bootstrap.sh missing"; exit 1; }

ENV=""
ENGINE_ARGS=(--platform --bootstrap)
while [ $# -gt 0 ]; do
  case "$1" in
    --env) ENV="$2"; ENGINE_ARGS+=(--env "$2"); shift 2 ;;
    --env=*) ENV="${1#*=}"; ENGINE_ARGS+=(--env="$ENV"); shift ;;
    *) ENGINE_ARGS+=("$1"); shift ;;
  esac
done
[ -n "$ENV" ] || { echo "usage: $0 --env <local|dev|qa|prod> [deploy.sh flags...]"; exit 1; }

"$SCRIPT_DIR/scripts/bootstrap.sh" --env "$ENV" --prepare-only
exec "$SCRIPT_DIR/../deploy.sh" "${ENGINE_ARGS[@]}"
```

(Remove the stray `[s -x ...]` line if kept accidentally — it is just a guard; the authoritative script content is the block below the `#!/usr/bin/env bash`.)

- [ ] **Step 2: Actually write the clean file content** (no stray line — use this as the file body):

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV=""
ENGINE_ARGS=(--platform --bootstrap)
while [ $# -gt 0 ]; do
  case "$1" in
    --env) ENV="$2"; ENGINE_ARGS+=(--env "$2"); shift 2 ;;
    --env=*) ENV="${1#*=}"; ENGINE_ARGS+=(--env="$ENV"); shift ;;
    *) ENGINE_ARGS+=("$1"); shift ;;
  esac
done
[ -n "$ENV" ] || { echo "usage: $0 --env <local|dev|qa|prod> [deploy.sh flags...]"; exit 1; }

"$SCRIPT_DIR/scripts/bootstrap.sh" --env "$ENV" --prepare-only
exec "$SCRIPT_DIR/../deploy.sh" "${ENGINE_ARGS[@]}"
```

- [ ] **Step 3: Dry-run end-to-end**

Run: `./platform/deploy.sh --env qa --dry-run`
Expected: `bootstrap.sh` runs `--prepare-only` (ssh sonnora-qa → infra ready), then deploy.sh dry-run resolves `PROJECT=platform`, env from `platform/env/qa.env`, composes `platform/docker/docker-compose.qa.yml`. No actual pull/up.

- [ ] **Step 4: chmod + shellcheck**

Run: `chmod +x platform/deploy.sh && shellcheck platform/deploy.sh && bash -n platform/deploy.sh`

- [ ] **Step 5: Commit (after user approval)**

```bash
git add platform/deploy.sh
git commit -m "feat(platform): deploy wrapper - prepare network, run engine with bootstrap"
```

---

## Task 8: Platform VPS edge templates

**Files:**
- Create: `/Users/hugo/Projects/sonnora-deploy/platform/vps/qa/userbrew.conf.tmpl`, `sentinel.conf.tmpl`, `imgvault.conf.tmpl`
- Create: same 3 for `dev/` and `prod/` (identical body, per-env DOMAIN/PORT resolved from `platform/env/<env>.env` at render time — the SAME file can be shared across envs; create `platform/vps/userbrew.conf.tmpl` etc. ONCE and let Task 2 loop read `platform/vps/$ENV/...`; to keep Task 2's glob simple, either (a) create `platform/vps/<env>/` dirs with copies, or (b) change Task 2 glob to `platform/vps/*.conf.tmpl`. RECOMMENDED: change Task 2 glob to `"$PROJECT_DIR"/vps/*.conf.tmpl` — single templates shared by all envs, values injected at render. Update Task 2's loop path accordingly.)

**Interfaces:**
- Consumes: Task 2 render contract (`\${DOMAIN} \${APP_HOST_IP} \${VPS_PORT}`), Task 3 per-service `DOMAIN`/`PORT`.
- Produces: nginx vhosts on the VPS for each platform service (certbot webroot `/var/www/astro`, reused pattern from rideshare).

> **Decision applied:** to avoid three duplicated dirs, use a single `platform/vps/` dir with one template per service, and adjust Task 2's loop to `for tmpl in "$PROJECT_DIR"/vps/*.conf.tmpl`. `basename "$tmpl" .conf.tmpl` stays the service name (`userbrew`, `sentinel`, `imgvault`), matching the `${base}_DOMAIN`/`${base}_PORT` vars.

- [ ] **Step 1: Write `platform/vps/userbrew.conf.tmpl`**

```
server {
  listen 80;
  server_name ${DOMAIN};

  location /.well-known/acme-challenge/ { root /var/www/astro; }
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl;
  http2 on;
  server_name ${DOMAIN};

  ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  include /etc/nginx/options-ssl-nginx.conf;
  ssl_dhparam /etc/nginx/ssl-dhparams.pem;

  add_header Strict-Transport-Security "max-age=63072000" always;
  add_header X-Frame-Options SAMEORIGIN always;
  add_header X-Content-Type-Options nosniff always;

  root /var/www/astro;
  index index.html;

  location / {
    proxy_pass http://${APP_HOST_IP}:${VPS_PORT};
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

- [ ] **Step 2: Write `sentinel.conf.tmpl` and `imgvault.conf.tmpl`**

Identical body; each template shares the SAME generic vhost (server_name/ port come from render-time `DOMAIN`/`VPS_PORT`). Copy `userbrew.conf.tmpl` verbatim for both.

- [ ] **Step 3: Render + assert no unresolved vars (needs Task 3 env)**

Run:
```bash
set -a; . platform/env/qa.env; set +a
for base in userbrew sentinel imgvault; do
  DOMAIN="$(eval "printf '%s' \"\$${base}_DOMAIN\"")"
  VPS_PORT="$(eval "printf '%s' \"\$${base}_PORT\"")"
  envsubst '${DOMAIN} ${APP_HOST_IP} ${VPS_PORT}' < "platform/vps/$base.conf.tmpl" \
    > "/tmp/$base-qa.conf"
  grep -L '\${' "/tmp/$base-qa.conf" && echo "$base OK: $DOMAIN -> $APP_HOST_IP:$VPS_PORT"
done
```
Expected: three lines `... OK: <domain>.qa.sonnora.mx -> 10.0.0.4:<port>`; no file still contains `${`.

- [ ] **Step 4: Update Task 2 loop glob** if you chose the single-dir variant (edit `deploy.sh` loop path to `"$PROJECT_DIR"/vps/*.conf.tmpl`), re-run `bash -n deploy.sh`.

- [ ] **Step 5: Commit (after user approval)**

```bash
git add platform/vps/
git commit -m "feat(platform): VPS edge templates for userbrew, sentinel, imgvault"
```

---

## Task 9: rideshare — adopt shared sentinel

**Files:**
- Modify: `/Users/hugo/Projects/rideshare/deploy/qa/bootstrap.sh` (and `dev`, `prod`, `local` variants — same edit)
- Modify: `/Users/hugo/Projects/rideshare/deploy/qa/self-host.yaml` (and `dev`, `prod`, `local`)
- Modify (minor): `/Users/hugo/Projects/rideshare/deploy/qa/.env.qa` — `.env.qa` write target; the SENTINEL_TOKEN line is removed entirely (no tokendown).

**Interfaces:**
- Consumes: shared `sentry-<env>` created by Task 6, engine additive-ref semantics (`ref` by name; policies merged per app+path).
- Produces: rideshare appends its API policies onto the shared sentinel; its bootstrap no longer mints/saves a token.

- [ ] **Step 1: Update `deploy/qa/self-host.yaml`**

Replace the `global.sentinel` block name form with a ref (keep the exact policy list):

```yaml
global:
  app:
    name: RideShare
    launch_url: https://rideshare.qa.sonnora.mx
    provider_type: password
    visibility: assigned
    registration_enabled: true
    flow: default-authentication-flow
  users:
    - username: rideshare-admin
      password: ${USERBREW_RIDESHARE_ADMIN_PASSWORD}
      roles:
        - admin
  sentinel:
    ref: sentry-qa
    policies:
      - path: /api/v1/**
        methods: [GET, POST, PUT, PATCH, DELETE]
        effect: allow
        priority: 100
  api_keys: []
```

- [ ] **Step 2: Remove the SENTINEL_TOKEN write from `deploy/qa/bootstrap.sh`**

Delete the block that writes `SENTINEL_TOKEN` into `$DIR/.env.${ENV:-qa}` (the `sed replace or append` lines, originally ~lines 82-94). Keep the report parsing for `application_id`/`sentinel_id` (still printed/logged). Keep every other line unchanged (login, blueprint apply, settings/console PUT, api-key creation).

- [ ] **Step 3: Idempotency + shellcheck**

Run: `shellcheck deploy/qa/bootstrap.sh` and `deploy/dev/bootstrap.sh` etc.
Expected: no errors.
Run twice against qa: `ENV=qa ./deploy/qa/bootstrap.sh` (if runnable from repo root as documented; otherwise `bash deploy/qa/bootstrap.sh`). Expected: second run applies cleanly (sentinel already exists by ref → no conflict) and DOES NOT modify `deploy/qa/.env.qa`.

- [ ] **Step 4: Commit (after user approval)**

```bash
git add deploy/qa/ deploy/dev/ deploy/prod/ deploy/local/
git commit -m "refactor(deploy): rideshare appends policies to shared sentry-<env>; drop per-app sentinel token"
```

---

## Task 10: mercadomio — local stack drops userbrew + joins infra

**Files:**
- Modify: `/Users/hugo/Projects/mercadomio/docker/docker-compose.yml`
- Modify (comment only): `/Users/hugo/Projects/mercadomio/scripts/setup-userbrew.sh`

**Interfaces:**
- Consumes: local platform stack (Task 4 `docker-compose.local.yml` + Task 6 bootstrap `--env local`) publishing userbrew 8090/5174 and `imgvault-server` on `infra`.
- Produces: local dev runs with ZERO bundled userbrew/imgvault/minio; backend reaches IdP at `http://localhost:8090` (unchanged defaults) and imgvault at `http://imgvault-server:8081` over `infra`.

- [ ] **Step 1: Remove the userbrew sidecar**

Delete from `docker/docker-compose.yml`: the entire `userbrew:` service block and its `env_file: docker/.env` + `./.env.local` references (lines ~140-187), and the `userbrew_data:` volume entry (line ~209).

- [ ] **Step 2: Remove imgvault/minio/create-buckets from the local compose**

Delete the local `imgvault`, `minio`, and `create-buckets` services. They now live in the platform local stack. If `create-buckets` also served the app-upload bucket, note that the platform buckets job creates `public` on `minio` — the platform must create the same bucket used in production (`create-buckets` there is `public`); keep the platform bucket name in sync (rename the `create-buckets` entrypoint target in Task 4 if mercadomio uploads go to a different bucket than `public`).

- [ ] **Step 3: Join `infra` and repoint imgvault**

Add an external network and attach backend:

```yaml
networks:
  infra:
    name: infra
    external: true
```

For the `backend` service (and any other service reaching imgvault): add `infra` to its `networks:` and change its imgvault env:

```yaml
    environment:
      IMGVAULT_URL: http://imgvault-server:8081
      IMGVAULT_API_KEY: ${IMGVAULT_API_KEY:-dev_api_key_123}
```

(Env file/overrides: `docker/.env` and `backend/.env` may pin `IMGVAULT_URL` — ensure no override points back to the removed `imgvault` host. USERBREW vars stay at `http://localhost:8090`.)

- [ ] **Step 4: Update `scripts/setup-userbrew.sh` header comment**

Change "first-run setup is NOT done here" note to state the LOCAL instance is now the local platform stack (`sonnora-platform/local`, bootstrap `--env local`) and remains the target of these OAuth reconciliations at `http://localhost:8090`.

- [ ] **Step 5: Validate compose + full local run**

Run: `docker compose -f docker/docker-compose.yml config --quiet`
Expected: OK (requires `infra` network to exist → run `./platform/scripts/bootstrap.sh --env local --prepare-only` against the sonnora-deploy checkout first, or `docker network create infra`).
Then with the platform local stack up:
Run: `docker compose -f docker/docker-compose.yml up -d --wait` (mercadomio)
Run: `./scripts/setup-userbrew.sh --env local`
Run: `curl -fsS http://localhost:8090/.well-known/openid-configuration`
Expected: compose config OK; app healthy; setup script logs in + reconciles OAuth clients (no failures); userbrew discovery 200.

- [ ] **Step 6: Commit (after user approval)**

```bash
git add docker/docker-compose.yml scripts/setup-userbrew.sh
git commit -m "refactor(local): drop userbrew/imgvault/minio sidecars; join shared infra network"
```

---

## Task 11: mercadomio — remote composes/env adopt platform stack

**Files:**
- Modify: `/Users/hugo/Projects/mercadomio/deploy/shared/docker/docker-compose.infra.yml`
- Modify: `/Users/hugo/Projects/mercadomio/deploy/shared/docker/docker-compose.app.yml`
- Modify: `/Users/hugo/Projects/mercadomio/deploy/env/qa.env`

**Interfaces:**
- Consumes: qa platform stack (services `imgvault-server` on `infra` at `http://imgvault-server:8081`).
- Produces: QA app stack shares the platform IdP+imgvault; app-level postgres/mongo/redis/directus remain per-app.

- [ ] **Step 1: Trim `docker-compose.infra.yml`**

Remove `imgvault`, `minio`, and `create-buckets` services. Keep `postgres`, `mongo`, `redis`, `directus` with the `mercadomio-net` network untouched.

- [ ] **Step 2: Join `infra` in `docker-compose.app.yml`**

Add to networks and give backend both networks:

```yaml
networks:
  default:
    name: mercadomio-net
    external: true
  infra:
    name: infra
    external: true
```

```yaml
  backend:
    networks:
      - default
      - infra
```

(frontend/admin stay on default.)

- [ ] **Step 3: Update `deploy/env/qa.env`**

Change:
```bash
IMGVAULT_URL=http://imgvault-server:8081
```
and keep `IMGVAULT_API_KEY="REDACTED"

- [ ] **Step 4: Validate composes + dry-run deploy**

Run (from mercadomio):
```bash
docker compose -f deploy/shared/docker/docker-compose.infra.yml config --quiet
docker compose -f deploy/shared/docker/docker-compose.app.yml config --quiet
grep -n 'imgvault' deploy/env/qa.env
```
Expected: both config OK; grep shows only `imgvault-server:8081` and the api key.
Run (cross-repo, optional when network permits): `./platform/deploy.sh --env qa --dry-run` from sonnora-deploy to confirm the shared stack still plans cleanly alongside app changes.

- [ ] **Step 5: Commit (after user approval)**

```bash
git add deploy/shared/docker/docker-compose.infra.yml deploy/shared/docker/docker-compose.app.yml deploy/env/qa.env
git commit -m "refactor(qa): consume shared platform userbrew+imgvault; app joins infra network"
```

---

## Task 12: Cross-repo verification + session docs

**Files:**
- Modify: `/Users/hugo/Projects/mercadomio/docs/SESSION_LOG.md`
- Modify: `/Users/hugo/Projects/mercadomio/docs/PROJECT_CONTEXT.md` (architecture changed)
- Modify: `/Users/hugo/Projects/mercadomio/docs/REQUIREMENTS.md` (only if requirements changed)

**Interfaces:**
- Verifies: Tasks 1-11 integrated state.

- [ ] **Step 1: Static verification sweep**

Run:
```bash
bash -n   # on every edited bash file: sonnora-deploy deploy.sh, platform/deploy.sh, platform/scripts/bootstrap.sh, rideshare bootstrap.sh, mercadomio scripts/setup-userbrew.sh
shellcheck deploy.sh platform/deploy.sh platform/scripts/bootstrap.sh         # sonnora-deploy
shellcheck deploy/qa/bootstrap.sh deploy/dev/bootstrap.sh deploy/prod/bootstrap.sh deploy/local/bootstrap.sh   # rideshare
docker compose -f docker/docker-compose.yml config --quiet                    # mercadomio local
docker compose -f deploy/shared/docker/docker-compose.infra.yml config --quiet
docker compose -f deploy/shared/docker/docker-compose.app.yml config --quiet
docker compose -f docker-compose.qa.yml config --quiet                        # platform qa (with SENTINEL_TOKEN=check)
```
Expected: all pass.

- [ ] **Step 2: Repository-run discipline for app code**

mercadomio: run `flutter analyze` and `go vet ./...` and the touched-area tests (per mercadomio/AGENTS.md) if any Go/Flutter code changed (none expected — this plan is ops-only; skip with a logged reason if zero code changes).

- [ ] **Step 3: Update session docs**

In `docs/SESSION_LOG.md`, add a dated entry: approved design (single platform stack per env, one shared sentinel `sentry-<env>`, platform owns sole SENTINEL_TOKEN, consumers drop bundled userbrew), the files changed per repo, the open items (Gitea registry auth for image pushes; DNS entries for `userbrew/sentinel/imgvault.<env>.sonnora.mx`; `IMGVAULT_API_KEY` shared-value rotation; credentialvault future). In `docs/PROJECT_CONTEXT.md`, update the deployment/architecture section: shared platform stack + `infra` external network + consumer model. Update `docs/REQUIREMENTS.md` only if a requirement literally changed (likely none).

- [ ] **Step 4: Commit docs (after user approval)**

```bash
git add docs/SESSION_LOG.md docs/PROJECT_CONTEXT.md
git commit -m "docs: record shared platform stack rollout"
```

---

## Self-Review

**1. Spec coverage.** The approved design's decisions map 1:1 to Global Constraints 1-14, and each constraint is enforced by at least one task: one shared sentinel (T5/T6/T9), sole token (T6, T9 removes token write), no bundled userbrew (T10), deployed once per env (T1/T4/T7), per-app infra stays (T11 keeps postgres/mongo/redis/directus), engine-only (T1/T2 never touch playbooks/roles), co-location (T3 host values), local mirrors shape (T4 local compose + T10), edge via register-vps (T2/T8), onboarding rule (T4 structure comments), git discipline (every task's commit gated), secrets (T3 prod values), verification (T12).

**2. Placeholder scan.** No TBD/TODO/"add handling"/"similar to Task N". Template duplication in T4/T8 is resolved by "copy verbatim + change name" with the exact body inline (T4) and the render deterministically driven by env vars (T8). The one placeholder-style hint ("if the engine rejects global.console, drop it — verified against rideshare...") is a deliberate verification-first instruction backed by a concrete fallback, not an unimplemented hole.

**3. Type consistency.** Service names used as DNS by consumers match across files: `userbrew-server` (T4, rideshare/mercadomio USERBREW_URL pattern), `imgvault-server` (T4 shared, T10/T11 consumers), `sentry-<env>` (T5 creates, T9 refs). Var contract `${base}_DOMAIN`/`${base}_PORT` used identically in T2 and T8. `SENTINEL_TOKEN` empty in T3 → filled in T6 → consumed by T4 `${SENTINEL_TOKEN:?}` and validated in T4 step 3. One inconsistency caught inline and resolved: Task 2's original glob `platform/vps/$ENV/*.conf.tmpl` vs Task 8's single-dir decision — Task 8 Step 4 and the Task 8 header note make the loop update explicit; the executor MUST apply that one-line change or stay with env dirs.

**Open risks recorded for executor (do not silently skip):**
- Gitea registry image availability (`gitea.sonnora.mx/sonnora-mx/userbrew/userbrew:latest`, `userbrew/sentinel:latest`, `mercadomio/imgvault:qa`). If pull fails, image push requires GITEA_TOKEN (docker login) — unresolved auth precondition; ask the user.
- DNS for `userbrew.sentinel.imgvault.<env>.sonnora.mx` must point to `VPS_HOST` before `--register-vps` cert issuance.
- First deploy order: run platform stack once to a health + first bootstrap BEFORE consumer-side cutover (tasks are ordered so T6/T7 validate before T10/T11).