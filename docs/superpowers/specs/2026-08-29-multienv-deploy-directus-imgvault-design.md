# Diseño: Despliegue multi-entorno (local/dev/qa/prod), userbrew compartido + registry Gitea + Directus/imgvault

**Fecha:** 2026-08-29
**Estado:** Aprobado (diseño revisado en sesión)
**Alcance:** infraestructura de despliegue completa de mercadomio (backend Go + storefront Flutter + admin_console Flutter + Directus + imgvault)

## 1. Contexto y objetivos

MercadoMío se despliega hoy solo a QA de forma artesanal (`deploy/deploy-qa.sh` que hace rsync + build en el host, GitHub Container Registry obsoleto, `setup-pi-production.sh` con Cloudflare). El stack local levanta su propio userbrew (pesado, ocupa memoria/disco en laptops de devs).

Se desplegará en 4 entornos siguiendo el patrón probado de **rideshare**, con imágenes por entorno publicadas al **registry de Gitea** (nada se builda en los servidores), **userbrew compartido por entorno** (los devs apuntan al de sonnora-dev, no corren uno local), **Directus como CMS** y **imgvault como servicio de imágenes**.

Objetivos:
1. Entornos `local | dev | qa | prod` con dominios `mercadomio.*.sonnora.mx`, comando único `./deploy.sh --env {local|dev|qa|prod}`.
2. TLS terminado en el VPS sonnora (certbot), nginx del VPS proxya a cada app server.
3. Imágenes docker publicadas a `gitea.sonnora.mx/sonnora-mx/mercadomio/{backend,frontend,admin}:{dev|qa|prod|latest}`; servidores solo hacen `docker pull` + `up`.
4. userbrew NO se corre en el stack de mercadomio: cada entorno usa la instancia compartida (`userbrew.{env}.sonnora.mx`), y los devs locales usan `userbrew.dev.sonnora.mx` vía peers de docker compose (o http://192.168.1.98) para no consumir recursos locales.
5. Registro de clientes OAuth `mercadomio-storefront` / `mercadomio-admin` en cada instancia compartida vía `scripts/setup-userbrew.sh --env {dev|qa|prod}`.
6. Migrar el medio de imágenes de Cloudinary a **Directus + imgvault**: admin sube imágenes a imgvault (Rust/Axum + MinIO + Postgres), storefront las sirve a través del backend (proxy seguro). Elimina dependencia de Cloudinary.
7. Fix del entorno dev actual: userbrew-dev en sonnora-dev corre con puertos aleatorios → `userbrew.dev.sonnora.mx` da 502. Se fijan puertos estables y se corrige la conf del VPS.

## 2. Decisiones tomadas

### 2.1 Entornos y topología

| Env    | Dominio                    | App server       | userbrew (compartido) | Registry tag |
|--------|----------------------------|------------------|-----------------------|--------------|
| local  | http://localhost           | docker en Mac     | userbrew.dev.sonnora.mx (por LAN/VPS) | —            |
| dev    | mercadomio.dev.sonnora.mx  | sonnora-dev (192.168.1.98) | userbrew.dev.sonnora.mx (mismo host) | dev          |
| qa     | mercadomio.qa.sonnora.mx   | sonnora-qa (192.168.1.88)  | userbrew.qa.sonnora.mx   | qa          |
| prod   | mercadomio.sonnora.mx      | sonnora-prod (192.168.1.90)| userbrew.sonnora.mx      | prod        |

- VPS sonnora (162.222.206.218) con nginx (`/root/sonnora-compose/nginx/mercadomio-{env}.conf`) + certbot → app server interno.
- App server corre todo el stack docker de mercadomio (backend, frontend, admin, directus, postgres, mongo, redis, imgvault, minio) con nginx-* por aplicación en el puerto 8080 del host (igual que rideshare-nginx).
- CORS: backend usa variable `CORS_ORIGINS` por entorno.

### 2.2 Registry Gitea (reemplaza GHCR)

- Las imágenes se publican desde la máquina dev o CI (Gitea Actions si se configura) con `scripts/publish-images.sh --env {dev|qa|prod}` que hace `docker login gitea.sonnora.mx` (token del secret `GITEA_TOKEN`) y push.
- Tags: `gitea.sonnora.mx/sonnora-mx/mercadomio/backend:dev`, `frontend:qa`, `admin:prod`, etc.

### 2.3 Stack de servicios (docker/docker-compose.yml local)

- Se agrega servicio `imgvault` (build `../../ff-imagevault`... ver 2.5) + `minio` + `postgres` (ya existe).
- Se remueve el servicio `userbrew` del compose local (devs usan el compartido). El backend apunta su `USERBREW_ISSUER`/`USERBREW_DISCOVERY_URL` a `http://192.168.1.98:3001` (LAN, alcanzable) o a `https://userbrew.dev.sonnora.mx` cuando esté fijado.

### 2.4 userbrew dev (sonnora-dev)

- Fijar puertos estables en `/home/hugo/userbrew-dev/docker-compose.yml`: server `3001:3000`, frontend `5173:5173`, sentinel `9000:9000`.
- Corregir conf VPS `dev.conf`: `userbrew.dev.sonnora.mx` → `10.0.0.6:3001` server + `:5173` frontend.

### 2.5 imgvault

- `ff-imagevault` (Rust/Axum, clonado en `~/Projects/ff-imagevault`) sube a MinIO y guarda metadata en Postgres. Se despliega como servicio del stack de mercadomio en cada entorno, expuesto como `imgvault.{env}.sonnora.mx` (opcional) y consumido por el backend.
- El backend expone `/api/imgvault/` (proxy con validación, como hoy `/api/directus/assets`) para no exponer imgvault directo al storefront.

### 2.6 Migración Directus

- Backend ya tiene `DirectusProxy` (`/api/directus/assets`). Se deja como ruta de assets genérica y se migra el código de Cloudinary (`cloudinary_handlers.go`, `config/cloudinary.go`, route `/api/images/products`). El catálogo de productos sigue en MongoDB (fuera de alcance: moverlo a Directus es otra migración).
- El upload de imágenes se hace vía imgvault, no Cloudinary.

## 3. Configuración de puesta en marcha (orden aproximado)

1. Fix userbrew dev + VPS dev.conf (desbloquea a todos).
2. `scripts/publish-images.sh` + Dockerfiles de frontend/admin/backend (admin necesita Dockerfile; frontend ya tiene).
3. `scripts/setup-userbrew.sh --env` parametrizado.
4. `deploy.sh` + estructura `deploy/{env}/.env` + `deploy/shared/*` (systemd/docker/nginx) + confs VPS por env.
5. Migración Directus/imgvault en backend.
6. Actualizar CORS / variables por env; retirar GHCR workflow.
7. (Opcional) CI en Gitea Actions para publicar imágenes.

## 4. Fuera de alcance

- Mover catálogo de productos de MongoDB a Directus (migración de datos separada).
- CI en GitHub Actions (se retira; sustituido por push local o Gitea Actions).
- App nativa iOS/Android; este diseño cubre web (Flutter web + Docker).