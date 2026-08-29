# MercadoMío Multi-Env + userbrew compartido + Gitea registry + Directus/imgvault — Plan de implementación

> **Para agentic workers:** REQUIRED SUB-SKILL: usa `superpowers:executing-plans` y trabaja task por task. Checkboxes `- [ ]`.

**Goal:** Desplegar mercadomio en 4 entornos (local/dev/qa/prod) con TLS en el VPS sonnora, imágenes docker publicadas al registry de Gitea (sin build en servidores), userbrew compartido por entorno (sin instancia local), y migrar el manejo de imágenes de Cloudinary a Directus + imgvault.

**Architecture:** Replica el patrón `deploy.sh --env {local|dev|qa|prod}` de rideshare: `deploy/{env}/.env` define app server/dominio/puertos; imágenes publicadas a `gitea.sonnora.mx/sonnora-mx/mercadomio/{backend,frontend,admin}:{dev|qa|prod|latest}`; el app server solo hace pull + up; el VPS termina TLS y proxya.

**Tech Stack:** bash, docker compose, nginx (VPS + app server), Go/Fiber, Flutter web (frontend + admin_console), Directus, imgvault (Rust/Axum + MinIO + Postgres), userbrew (IdP compartido).

**Spec:** `docs/superpowers/specs/2026-08-29-multienv-deploy-directus-imgvault-design.md`

## Global Constraints
- puertos app server en servers: backend `8083`, frontend `8084`, admin `8085`, directus `8055`, imgvault `8081`, minio `9000/9001`.
- números: valores de `deploy/{env}/.env` se toman textuales.
- todo comando remoto verifica con `set -euo pipefail` y `say/die` como helpers (estilo rideshare).
- no build en servers: solo `docker pull` del registry Gitea.
- api keys/secrets van en `deploy/{env}/.env` (no en git de imágenes); backend lee env vars en runtime.
- commit pequeño por task.

---

### Task 1: Fix versión de Go en backend/Dockerfile

**Files:**
- Modify: `backend/Dockerfile:1` (`golang:1.24.5-alpine3.21` → `golang:1.25.0-alpine3.21`)

**Interfaces:**
- Produces: imagen backend compilable con go.mod (`go 1.25.0`).

- [ ] **Step 1: Editar línea de builder**

`FROM golang:1.24.5-alpine3.21 AS builder` → `FROM golang:1.25.0-alpine3.21 AS builder`

- [ ] **Step 2: Verificar build**

Run: `docker build -t mercadomio/backend:test-src .` en `backend/`
Expected: build OK (go mod download + go build con go 1.25.0)

- [ ] **Step 3: Commit**

```bash
git add backend/Dockerfile
git commit -m "fix: bump backend Dockerfile to Go 1.25.0 (matches go.mod)"
```

---

### Task 2: Dockerfile de admin_console + `.env.example` de admin

**Files:**
- Create: `admin_console/Dockerfile`
- Create: `admin_console/.env.example`
- Modify: `admin_console/lib/services/admin_auth_service.dart`

**Interfaces:**
- Consumes: `String.fromEnvironment('USERBREW_ISSUER')` y `'USERBREW_CLIENT_ID'` (dotenv).
- Produces: imagen `admin` publicable al registry (puerto 80, nginx).

- [ ] **Step 1: Crear Dockerfile**

```dockerfile
# syntax=docker/dockerfile:1
FROM ghcr.io/cirruslabs/flutter:3.32.8 AS build
WORKDIR /app
COPY . .
ARG USERBREW_ISSUER=http://localhost:8090
ARG USERBREW_CLIENT_ID=mercadomio-admin
RUN flutter build web \
  --dart-define=USERBREW_ISSUER=$USERBREW_ISSUER \
  --dart-define=USERBREW_CLIENT_ID=$USERBREW_CLIENT_ID

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

- [ ] **Step 2: Refactor `admin_auth_service.dart` para usar defines**

Reemplazar los valores hardcoded:
- `issuer: 'http://localhost:8090'` → `issuer: String.fromEnvironment('USERBREW_ISSUER', defaultValue: 'http://localhost:8090'),`
- `clientId: 'mercadomio-admin'` → `clientId: String.fromEnvironment('USERBREW_CLIENT_ID', defaultValue: 'mercadomio-admin'),`
- `redirectUri: 'http://localhost:3100/auth/callback'` → derivarlo de `USERBREW_REDIRECT_URI` define (default `http://localhost:3100/auth/callback`).

- [ ] **Step 3: Crear `.env.example` de admin**

```
USERBREW_ISSUER=http://localhost:8090
USERBREW_CLIENT_ID=mercadomio-admin
USERBREW_REDIRECT_URI=http://localhost:3100/auth/callback
```

- [ ] **Step 4: Verificar build local**

Run: `docker build -t mercadomio/admin:test .` en `admin_console/`
Expected: build OK (flutter build web + nginx)

- [ ] **Step 5: Commit**

```bash
git add admin_console/Dockerfile admin_console/.env.example admin_console/lib/services/admin_auth_service.dart
git commit -m "feat: dockerize admin_console with env-driven userbrew config"
```

---

### Task 3: Parametrizar `scripts/setup-userbrew.sh` con `--env`

**Files:**
- Modify: `scripts/setup-userbrew.sh`

**Interfaces:**
- Consumes: env var `ENV` (dev|qa|prod); defaults por entorno.
- Produces: `ENV=... scripts/setup-userbrew.sh` registra clientes en la instancia correcta.

- [ ] **Step 1: Aceptar env arg en el script**

Agregar parsing de `--env {local|dev|qa|prod}` (default `local`) y tabla de URLs:
- local  → `http://localhost:8090`, redirects `http://localhost:3000/auth/callback` y `http://localhost:3100/auth/callback`
- dev    → `https://userbrew.dev.sonnora.mx`, redirects `https://mercadomio.dev.sonnora.mx/auth/callback` y `https://mercadomio.dev.sonnora.mx/admin/auth/callback`
- qa     → `https://userbrew.qa.sonnora.mx`, redirects `https://mercadomio.qa.sonnora.mx/auth/callback` y `https://mercadomio.qa.sonnora.mx/admin/auth/callback`
- prod   → `https://userbrew.sonnora.mx`, redirects `https://mercadomio.sonnora.mx/auth/callback` y `https://mercadomio.sonnora.mx/admin/auth/callback`

definir `USERBREW_URL`, `STOREFRONT_REDIRECT`, `ADMIN_REDIRECT` a partir de `ENV`.

- [ ] **Step 2: shellcheck + dry-run**

Run: `bash -n scripts/setup-userbrew.sh`
Expected: sin errores de parseo.

- [ ] **Step 3: Commit**

```bash
git add scripts/setup-userbrew.sh
git commit -m "feat: parametrize setup-userbrew.sh with --env for shared IdPs"
```

---

### Task 4: Publicar imágenes al registry Gitea (`scripts/publish-images.sh`)

**Files:**
- Create: `scripts/publish-images.sh`

**Interfaces:**
- Consumes: env vars `GITEA_TOKEN`, `ENV` (dev|qa|prod); variables de `deploy/{env}/.env`.
- Produces: imágenes `gitea.sonnora.mx/sonnora-mx/mercadomio/{backend,frontend,admin}:$ENV`.

- [ ] **Step 1: Escribir script**

```bash
#!/usr/bin/env bash
# Publishes mercadomio images to the Gitea registry (per environment).
# Usage: GITEA_TOKEN=xxx scripts/publish-images.sh --env qa
set -euo pipefail
REGISTRY="gitea.sonnora.mx/sonnora-mx/mercadomio"
ENV=""
while [ $# -gt 0 ]; do
  case "$1" in
    --env) ENV="$2"; shift 2 ;;
    --env=*) ENV="${1#--env=}"; shift ;;
    *) echo "unknown flag: $1"; exit 1 ;;
  esac
done
[ -n "$ENV" ] || { echo "missing --env {dev|qa|prod}"; exit 1; }
[ -n "${GITEA_TOKEN:-}" ] || { echo "missing GITEA_TOKEN"; exit 1; }

echo "==> Login to $REGISTRY"
echo "$GITEA_TOKEN" | docker login gitea.sonnora.mx -u hugomf --password-stdin

build() {
  local name="$1" ctx="$2" dockerfile="$3" build_args="${4:-}"
  local tag="$REGISTRY/$name:$ENV"
  echo "==> Building $tag"
  docker build --push -t "$tag" -f "$dockerfile" $build_args "$ctx"
}

build backend backend/Dockerfile backend
build frontend frontend/Dockerfile frontend
build admin admin_console/Dockerfile admin \
  --build-arg USERBREW_ISSUER=https://userbrew.$ENV.sonnora.mx
echo "==> Published $REGISTRY/*:$ENV"
```

- [ ] **Step 2: bash -n**

Run: `bash -n scripts/publish-images.sh`
Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
chmod +x scripts/publish-images.sh
git add scripts/publish-images.sh
git commit -m "feat: add Gitea registry publish script (per env)"
```

---

### Task 5: quitr GHCR workflow

**Files:**
- Delete: `.github/workflows/docker-publish.yml`

- [ ] **Step 1: Borrar workflow GHCR**

`rm .github/workflows/docker-publish.yml`

- [ ] **Step 2: Commit**

```bash
git add -A .github/workflows
git commit -m "chore: remove GHCR publish workflow (replaced by Gitea registry)"
```

---

### Task 6: Estructura `deploy/` y `deploy.sh`

**Files:**
- Create: `deploy.sh`
- Create: `deploy/local/.env`
- Create: `deploy/dev/.env`, `deploy/dev/sonnora/vps.conf`
- Create: `deploy/qa/.env`, `deploy/qa/sonnora/vps.conf`
- Create: `deploy/prod/.env`, `deploy/prod/sonnora/vps.conf`
- Create: `deploy/shared/docker/docker-compose.app.yml`
- Create: `deploy/shared/docker/docker-compose.infra.yml`
- Create: `deploy/shared/docker/docker-compose.nginx.yml`
- Create: `deploy/shared/nginx/app-server.conf`
- Create: `deploy/shared/systemd/mercadomio-backend.service`

**Interfaces:**
- Consumes: `scripts/publish-images.sh` (publica previamente).
- Produces: comando `./deploy.sh --env {local|dev|qa|prod}` que en remotos hace `docker compose pull` + `up`, escribe `.env` del servidor, instala conf nginx y (con `--register-vps`) VPS conf + cert.

- [ ] **Step 1: Escribir `.env` por entorno** (ver valores abajo)

dev: `APP_HOST=sonnora-dev`, `DOMAIN=mercadomio.dev.sonnora.mx`, `APP_DIR=/opt/mercadomio`, `WEB_ROOT=/var/www/mercadomio`, `REGISTRY_IMAGE_TAG=dev`, `USERBREW_ISSUER=https://userbrew.dev.sonnora.mx`, `DIRECTUS_URL=http://127.0.0.1:8055`, `IMGVAULT_URL=http://127.0.0.1:8081`, `BACKEND_PORT=8083`, `FRONTEND_PORT=8084`, `ADMIN_PORT=8085`, `APP_HOST_IP=10.0.0.6`, `VPS_HOST=sonnora`.

qa: `APP_HOST=sonnora-qa`, `DOMAIN=mercadomio.qa.sonnora.mx`, `APP_HOST_IP=10.0.0.4`, resto igual, `REGISTRY_IMAGE_TAG=qa`.

prod: `APP_HOST=sonnora-prod`, `DOMAIN=mercadomio.sonnora.mx`, `APP_HOST_IP=192.168.1.90`, `REGISTRY_IMAGE_TAG=prod`, `VPS_HOST=sonnora`.

local: `DOCKER_HOST_IP=localhost`, `REGISTRY_IMAGE_TAG=local`.

- [ ] **Step 2: Escribir `deploy.sh`**

Basado en rideshare `deploy.sh`, adaptado a mercadomio: local → `(cd docker && docker compose up -d)`; remoto → subir `deploy/shared/*`, `docker compose pull` + `up -d` con los tags del registry, escribir `.env`, instalar nginx conf, y con `--register-vps` subir `vps.conf` + certbot. Los puertos del app server se pasan vía `docker-compose.nginx.yml` (envsubst).

- [ ] **Step 3: Escribir confs nginx (app server + VPS)**

`deploy/shared/nginx/app-server.conf`: nginx del app server en `:8080` proxya `/api`→`host.docker.internal:8083`, `/admin`→num admin, `/assets`→SPAs; carga SPA desde `/var/www/mercadomio`.

`deploy/{env}/sonnora/vps.conf`: server_name `mercadomio.{env}.sonnora.mx`, `location /` → `http://$APP_HOST_IP:8080`, `.well-known/acme-challenge` → `/var/www/astro`, 301→443 + bloque 443 con cert.

- [ ] **Step 4: bash -n + docker compose config**

Run: `bash -n deploy.sh && bash -n deploy/shared/...`
Run: `docker compose -f deploy/shared/docker/docker-compose.app.yml config --quiet` (después de completar Task 7)
Expected: OK.

- [ ] **Step 5: Commit**

```bash
git add deploy.sh deploy/
git commit -m "feat: unified deploy.sh + per-env configs (local/dev/qa/prod)"
```

---

### Task 7: Composes remotos (`deploy/shared/docker/*`) e integrar en `docker/docker-compose.yml`

**Files:**
- Create: `deploy/shared/docker/docker-compose.infra.yml`
- Create: `deploy/shared/docker/docker-compose.app.yml`
- Create: `deploy/shared/docker/docker-compose.nginx.yml`
- Modify: `docker/docker-compose.yml`

**Interfaces:**
- Consumes: variables de `deploy/{env}/.env` (`IMGVAULT_URL`, `DIRECTUS_URL`, `USERBREW_ISSUER`, `REGISTRY_IMAGE_TAG`, puertos).
- Produces: infra (postgres/mongo/redis/directus/imgvault/minio) y app (backend/frontend/admin desde registry) desplegables por compose en el app server.

- [ ] **Step 1: `docker-compose.infra.yml`** — postgres/mongo/redis/directus (tomado de `docker-compose.qa.yml`) + imgvault (de `ff-imagevault/docker-compose.yml`) + minio. Imágenes del registry/imgvault por tag `REGISTRY_IMAGE_TAG`.

- [ ] **Step 2: `docker-compose.app.yml`** — backend/frontend/admin con `image: gitea.sonnora.mx/sonnora-mx/mercadomio/{backend,frontend,admin}:$REGISTRY_IMAGE_TAG`, envs de backend (USERBREW_ISSUER, DIRECTUS_URL, IMGVAULT_URL, MONGO_URI, REDIS_ADDR, CLOUDINARY_* removidos).

- [ ] **Step 3: `docker-compose.nginx.yml`** — nginx:alpine :8080 montando SPA de `/var/www/mercadomio` + conf renderizada.

- [ ] **Step 4: Modificar `docker/docker-compose.yml` local** — quitar servicio `userbrew`; envs del backend a `USERBREW_ISSUER=http://192.168.1.98:3001` y `USERBREW_DISCOVERY_URL=http://192.168.1.98:3001/.well-known/openid-configuration` (dev compartido); quitar `depends_on: userbrew`. Agregar `imgvault` + `minio` opcionales (profile `imgvault`) o permanecer off por defecto si no hay imágenes aún.

- [ ] **Step 5: Validar composes**

Run: `docker compose -f deploy/shared/docker/docker-compose.infra.yml config --quiet`
Run: `docker compose -f deploy/shared/docker/docker-compose.app.yml config --quiet`
Run: `docker compose -f docker/docker-compose.yml config --quiet`
Expected: sin errores de sintaxis (requiere Task 3/4 completadas para tags).

- [ ] **Step 6: Commit**

```bash
git add deploy/shared/docker docker/docker-compose.yml
git commit -m "feat: per-env docker compose (infra + app from Gitea registry); drop local userbrew"
```

---

### Task 8: imgvault — quitar Cloudinary, proxy seguro en backend

**Files:**
- Delete: `backend/handlers/cloudinary_handlers.go`, `backend/config/cloudinary.go`
- Create: `backend/handlers/imgvault_handlers.go`
- Modify: `backend/routes/image_routes.go`, `backend/routes/setup.go`, `backend/.env.example`

**Interfaces:**
- Consumes: env `IMGVAULT_URL` (backend→imgvault interno); storefront→backend `/api/imgvault/images/:id/file`.

- [ ] **Step 1: `imgvault_handlers.go`** — proxy `GET/POST /api/imgvault/*` a `IMGVAULT_URL` validando path (solo `images/{uuid}/file` y `upload`), con timeout.

- [ ] **Step 2: Actualizar `setup.go`** — quitar Cloudinary init/route, iniciar `imgvaultHandlers` con `IMGVAULT_URL` y pasarlo a `SetupImageRoutes`.

- [ ] **Step 3: Actualizar `.env.example`** — reemplazar bloque Cloudinary por `IMGVAULT_URL=http://localhost:8081`.

- [ ] **Step 4: Test + build**

Run: `cd backend && go build ./... && go vet ./...` (después de limpiar import no usado)
Run: `cd backend && go test ./...`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A backend
git commit -m "feat: swap Cloudinary for imgvault secure proxy in backend"
```

---

### Task 9: Fix userbrew dev (sonnora-dev) + VPS dev.conf

**Files (remoto):**
- Modify: `sonnora-dev:/home/hugo/userbrew-dev/docker-compose.yml`
- Modify: `sonnora:/root/sonnora-compose/nginx/dev.conf`

- [ ] **Step 1: Fijar puertos estables en userbrew-dev**

`ssh sonnora-dev`; en `/home/hugo/userbrew-dev/docker-compose.yml`: server `38123:3000` → `3001:3000`, frontend `38231:5173` → `5173:5173`, sentinel `38321:9000` → `9000:9000`.
`docker compose up -d` en ese dir.

- [ ] **Step 2: Corregir VPS dev.conf**

`ssh sonnora`; en `/root/sonnora-compose/nginx/dev.conf` corregir `userbrew.dev.sonnora.mx` → `10.0.0.6:3001` (server) y `:5173` (frontend). `docker exec sonnora-nginx nginx -t && nginx -s reload`.

- [ ] **Step 3: Verificar**

Run: `curl -sf https://userbrew.dev.sonnora.mx/health`
Expected: 200 / ok.

- [ ] **Step 4: Commit** (si los cambios remotos se versionan en el repo userbrew; sino, solo registro)

---

### Task 10: Deploy QA end-to-end (prueba del comando unificado)

**Files:**
- Requiere: Tasks 1–7.

- [ ] **Step 1: Publicar imágenes QA**

Run: `. deploy/qa/.env && GITEA_TOKEN=$(cat ~/.config/gitea/token 2>/dev/null || echo $GITEA_TOKEN) scripts/publish-images.sh --env qa` (si GITEA_TOKEN no está, pedirlo una vez).

- [ ] **Step 2: Registrar clientes en userbrew QA**

Run: `ENV=qa scripts/setup-userbrew.sh`

- [ ] **Step 3: Deploy**

Run: `./deploy.sh --env qa --register-vps`
Expected: frontend/backend/admin responden en `https://mercadomio.qa.sonnora.mx`.

- [ ] **Step 4: Verificación**

Run: `curl -sf https://mercadomio.qa.sonnora.mx/api/products | head -c 200`
Expected: JSON.

- [ ] **Step 5: Commit** (si hay fixes de deploy)

---

### Task 11: Flutter build web para frontend parametrizado por env

**Files:**
- Modify: `frontend/Dockerfile`

**Interfaces:**
- Consumes: `ARG USERBREW_ISSUER`, `ARG USERBREW_REDIRECT_URI`, `ARG API_URL` (build-time `flutter build web --dart-define`).
- Produces: imágenes frontend por entorno en el registry.

- [ ] **Step 1: Parametrizar Dockerfile frontend**

```dockerfile
FROM ghcr.io/cirruslabs/flutter:3.32.8 AS build
WORKDIR /app
COPY . .
ARG API_URL=https://localhost
ARG USERBREW_ISSUER=http://localhost:8090
ARG USERBREW_REDIRECT_URI=http://localhost:3000/auth/callback
RUN flutter build web \
  --dart-define=API_URL=$API_URL \
  --dart-define=USERBREW_ISSUER=$USERBREW_ISSUER \
  --dart-define=USERBREW_REDIRECT_URI=$USERBREW_REDIRECT_URI
FROM nginx:alpine ...
```

- [ ] **Step 2: Verificar que frontend lea dart-defines**

Confirmar `frontend/lib/services/auth_service.dart` y `api` usan `String.fromEnvironment('API_URL')`, etc. (si usan dotenv, migrar a defines o inyectar ambos).

- [ ] **Step 3: Construir local**

Run: `docker build -t mercadomio/frontend:test .` en `frontend/`
Expected: OK.

- [ ] **Step 4: Commit**

```bash
git add frontend/Dockerfile frontend/lib
git commit -m "feat: parametrize frontend build with per-env dart-defines; drop dotenv"
```

---

<!-- Express checkpoints: after Task 6, 7, 8 → request review before proceeding -->