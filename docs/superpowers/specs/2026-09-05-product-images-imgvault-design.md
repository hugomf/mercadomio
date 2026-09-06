# Diseño: Migración de imágenes de producto a imgvault

**Fecha:** 2026-09-05
**Estado:** Aprobado (revisado en sesión)
**Alcance:** reemplazo completo de Cloudinary por imgvault como repositorio de imágenes de producto en mercadomio (backend Go + seed + despliegue local/entornos)

## 1. Contexto y objetivos

El catálogo de productos vive en MongoDB y hoy sus imágenes se guardan como URLs de Cloudinary. El backend ya tiene proxies a imgvault (`imgvault_handlers.go`, rutas `/api/imgvault/images/:id/file` y `/api/imgvault/upload`), y `backend/handlers/cloudinary_handlers.go` + `backend/config/cloudinary.go` ya fueron eliminados. Lo que falta es la migración completa del flujo de imágenes:

1. Eliminar Cloudinary del seed (`seed/scrape-natura-api.sh` sigue subiendo a `api.cloudinary.com`).
2. Guardar **ID de imgvault** en el modelo de producto (no la URL completa).
3. Que el **backend resuelva y sirva** las imágenes (el storefront/admin nunca tocan imgvault directo).
4. Limpiar config legada de Cloudinary (`.env`, scripts de deploy).
5. Dejar imgvault + MinIO activos por defecto en el stack local (instancia única para storefront y admin).

Fuera de alcance: backfill de imágenes legacy (Cloudinary URLs actuales en BD se dejan hasta expirar), mover el catálogo de MongoDB a Directus, y apps nativas.

## 2. Decisiones tomadas

### 2.1 Modelo de datos — guardar UUID de imgvault (sin migración de schema)

- Se reutiliza el campo existente `imageUrl` (`services.Product.ImageURL`, `bson:"imageUrl"`) para guardar el **UUID de imgvault** devuelto por `POST /api/v1/upload`.
- Aplica igual a `images[].url` (ProductImage) y `Variant.ImageURL` cuando se seteen.
- No hay cambio de schema en MongoDB; productos legacy con URLs `http(s)://` siguen funcionando.

### 2.2 Resolver en el backend — backend resuelve y sirve

Nuevo paquete `backend/imageurl` con:

```go
type Resolver struct{}
func Resolve(stored, baseURL string) string
```

Regla:

| Valor guardado              | Resultado                                    |
|-----------------------------|----------------------------------------------|
| vacío                       | `""`                                         |
| `http(s)://...` (legacy)    | passthrough idéntico                         |
| UUID válido                 | `{baseURL}/api/imgvault/images/{uuid}/variant/card` |

- `baseURL` = `c.BaseURL()` del request activo (host correcto en dev y detrás del reverse proxy).
- Variante elegida para la imagen principal: **`card`** (600×600, cover, webp q85, ya generada por imgvault en el upload).
- Choke points donde se aplica antes de responder JSON:
  - `product_handlers.GetProducts` (lista simple + búsqueda) y `GetProduct`.
  - `category_handlers` (GetCategories/GetCategory) para `services.Category.ImageURL`.
  - `order_handlers` (historial/detalle, incl. admin) — el snapshot `OrderItem.ImageURL` se resuelve al renderizar, no al crear la orden.
- El resto de los campos de producto que no contienen imágenes no se tocan.

### 2.3 Ruta de variantes en el backend

Agregar a `image_routes.go`:

```
GET /api/imgvault/images/:id/variant/:variant
```

- Valida `:variant` ∈ `{thumbnail, card, hero, icon}` (presets que imgvault genera al subir).
- Rechaza (400) UUID inválido vía el regex `isUUID` existente.
- Forwardea a `{imgvault}/api/v1/images/:id/variant/:variant` reutilizando `doRequest`/`ImgVaultFileProxy` pattern.

### 2.4 Seed — subir a imgvault en vez de Cloudinary

`seed/scrape-natura-api.sh`:

- Eliminar: sourcing de `CLOUDINARY_CONFIG_FILE`, chequeos de `CLOUDINARY_CLOUD_NAME/API_KEY/API_SECRET`, función `upload_to_cloudinary`, y mensajes relacionados.
- Nueva función `upload_to_imgvault`: descarga la imagen original de Natura a un archivo temporal → `curl -F "file=@tmp"` a `$API_URL/api/imgvault/upload` (proxy del backend) → parsea `id` del JSON → devuelve el UUID.
- El payload del producto sigue igual, pero `imageUrl` = UUID de imgvault (no `secure_url`).
- El script sigue requiriendo las demás envs que ya usa (`API_URL`, Natura, etc.).

### 2.5 Limpieza de config Cloudinary

- `backend/local.env`: eliminar bloque `CLOUDINARY_*`.
- `deploy/setup-pi-production.sh` (líneas ~132-135): eliminar las 3 variables `CLOUDINARY_*` que emite.
- No queda referencia de Cloudinary en código Go ni en el seed.

### 2.6 Despliegue — instancia única activa

`docker/docker-compose.yml`:

- Quitar `profiles: ["imgvault"]` de los servicios `minio`, `imgvault` y `create-buckets` para que `docker compose up -d` los levante por defecto.
- Mantener healthchecks (`minio /minio/health/live`, `curl /health`) y volúmenes `minio_data`/`imgvault_data`.
- Verificar que `deploy/shared/docker/docker-compose.infra.yml` ya incluye imgvault + minio para dev/qa/prod (ajustar si falta).
- La única instancia de imgvault sirve a storefront y admin (el admin resuelve también vía backend).

### 2.7 imgvault — sin cambios de código

- `POST /api/v1/upload` ya devuelve `id` y genera las 4 variantes.
- El backend (con `IMGVAULT_API_KEY`) es el único ingress; storefront/admin consumen los resolved URLs del backend.
- Imágenes de Natura son jpeg/gif < 10MB y pasan el filtro NSFW/watermark según defaults.

## 3. Configuración de puesta en marcha (orden)

1. Backend: `backend/imageurl` resolver + wiring en handlers.
2. Backend: ruta `/api/imgvault/images/:id/variant/:variant`.
3. Seed: swap Cloudinary → imgvault.
4. Compose: activar imgvault/minio por defecto; revisar infra compose de entornos.
5. Limpieza de `.env`/`setup-pi-production.sh`.
6. Verificación.

## 4. Pruebas y verificación

- Backend: `cd backend && go build ./... && go vet ./... && go test ./...`.
- Seed: `bash -n seed/scrape-natura-api.sh`.
- Compose local: `docker compose -f docker/docker-compose.yml config --quiet`.
- Live: subir una imagen de Natura vía `POST /api/imgvault/upload` → obtener UUID; `GET /api/products/:id` devuelve `imageUrl` resuelto a `/variant/card` y los bytes responden 200.
- Sin cambios Dart → no corre `flutter analyze`.