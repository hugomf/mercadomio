# Diseño: Autenticación OIDC con userbrew en MercadoMío

**Fecha:** 2026-08-21
**Estado:** Aprobado (diseño revisado en sesión)
**Alcance:** backend Go + storefront Flutter + admin_console Flutter + docker-compose

## 1. Contexto y objetivos

MercadoMío hoy tiene autenticación propia: el backend Go emite JWTs HMAC-SHA256 (`backend/middleware/auth.go`), con endpoints locales `POST /api/auth/register` y `POST /api/auth/login`. Los frontends Flutter envían `Authorization: Bearer` y guardan el token solo en memoria (sin persistencia).

Se integrará [userbrew](https://github.com/sonnora-mx/userbrew) (IdP Rust/Axum, clonado en `~/Projects/userbrew`) como proveedor de identidad vía **OIDC completo**, con soporte de **login y registro con Google**.

Objetivos:
1. Un solo source of truth de identidad (userbrew); eliminar login local del backend.
2. Login/registro hospedados en userbrew (password + Google) mediante redirect.
3. Backend valida tokens RS256 vía JWKS; sin secretos compartidos.
4. Migrar usuarios existentes de MongoDB a userbrew preservando su historial.

## 2. Decisiones tomadas

| Decisión | Elección |
|---|---|
| Arquitectura | OIDC completo (Authorization Code + PKCE), modelo Bearer se mantiene |
| Superficies | Storefront + admin_console |
| Despliegue | userbrew como servicio en el docker-compose de MercadoMío |
| Social login | Google (provider nativo de userbrew) |
| Usuarios existentes | Script de migración Mongo → userbrew |
| UX de login | Redirect al hosted-ui de userbrew (no renderer nativo) |

## 3. Arquitectura

```
Flutter web (storefront :3000 / admin :3100)
  │ 1. click "Iniciar sesión"
  │ 2. redirect ──────────────────►  userbrew (:8090)
  │                                  GET /oauth/authorize?client_id=...&code_challenge=...
  │                                  hosted-ui: password │ "Continuar con Google" │ registro
  │ 4. callback ◄──────────────────  3. redirect a {app}/auth/callback?code=...
  │ 5. POST /oauth/token (PKCE exchange, directo desde la app, cliente público)
  │ 6. guarda tokens (GetStorage/localStorage) + perfil (/userinfo)
  ▼
Go backend (:8080)  ── Bearer access_token ──►  middleware valida RS256
                                                JWKS cacheado de /.well-known/openid-configuration
```

Puntos clave:
- **Cliente público**: las apps Flutter usan PKCE, sin client_secret.
- **Scopes**: `openid profile email offline_access` (refresh token si userbrew lo emite; si no, re-login silencioso al expirar).
- **Roles**: pertenencia al grupo/rol `mercadomio-admin` en userbrew llega como claim; el backend lo usa para rutas admin.

## 4. Componentes

### 4.1 Servicio userbrew (docker-compose)

- Nuevo servicio `userbrew` en `docker-compose.yml`, puerto `8090`, imagen construida del repo (`Dockerfile.runtime`), volumen persistente para su DB SQLite.
- Env: `USERBREW_PUBLIC_URL=http://localhost:8090`, `DATABASE_URL`, credenciales Google (ver §4.5).
- Bootstrap idempotente (script `scripts/setup-userbrew.sh`) que crea:
  - Apps OAuth públicas: `mercadomio-storefront` (redirect `http://localhost:3000/auth/callback`) y `mercadomio-admin` (redirect `http://localhost:3100/auth/callback`). Redirect URIs sobreescribibles por env para QA/prod.
  - Rol/grupo `mercadomio-admin`.
- Healthcheck sobre `GET /health`.

### 4.2 Backend Go

- **Nuevo middleware JWKS** (`middleware/auth.go` reescrito):
  - Deps: se mantiene `golang-jwt/jwt/v5`; se agrega `github.com/MicahParks/keyfunc/v3` (JWKS + refresco automático).
  - Issuer/audience desde env: `USERBREW_ISSUER` (default `http://localhost:8090`), audience = client_id de la app correspondiente.
  - Validación: firma RS256, `exp`, `iss`, `aud`. `kid` desconocido → un refetch de JWKS antes de rechazar.
- **Claims → identidad**: `sub` (id userbrew), `email`, `name`, `roles` (los tokens de userbrew exponen roles resueltos, no grupos).
- **Upsert transparente** (`services/auth_service.go`): si `sub` nuevo → buscar usuario local por `email`; si existe, vincular (`userbrewSub` nuevo campo en colección `users`); si no, crear usuario. Preserva órdenes/carritos históricos.
- **Admin**: middleware adicional que exige el rol `mercadomio-admin` en el claim `roles`.
- **Endpoints eliminados**: `POST /api/auth/register`, `POST /api/auth/login`. Se conserva `GET /api/auth/profile` (ahora responde desde claims + upsert).

### 4.3 Storefront Flutter

- Nuevo `OidcAuthService` (reemplaza lógica de `AuthService`):
  - PKCE manual: `crypto` para S256 (`code_verifier` aleatorio 43–128 chars, guardado en memoria entre redirect y callback).
  - Discovery dinámico desde `/.well-known/openid-configuration` (endpoints no hardcodeados).
  - Exchange `POST /oauth/token` con `grant_type=authorization_code`.
  - Persistencia con `get_storage` (nueva dep): access/refresh token + perfil. Resuelve el TODO existente de storage.
  - Logout: clear local + redirect a end-session de userbrew.
- Ruta `/auth/callback`: widget que lee `code`/`error` de query params, completa el exchange y navega a home o pantalla de error.
- Pantalla login simplificada: botón "Iniciar sesión" (→ authorize URL). El hosted-ui ofrece password, Google y registro (enrollment flow).
- Dev: `flutter run --web-port 3000` fijo (requerido para redirect URI estable).

### 4.4 Admin console

- Mismo `OidcAuthService` como copia adaptada (client `mercadomio-admin`, puerto dev fijo `3100`); si ambas copias divergen en el futuro se extraerá un paquete compartido.
- Client `mercadomio-admin`, puerto dev fijo `3100`.
- Gate: tras login se verifica claim `mercadomio-admin`; sin él → pantalla "Sin acceso".

### 4.5 Google auth

- Provider Google habilitado en ambas apps dentro de userbrew (soporte nativo en `userbrew-oauth/google.rs`).
- Env del servicio userbrew: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.
- **Prerrequisito (usuario):** OAuth Client tipo Web en Google Cloud Console con redirect autorizado hacia el callback de Google de userbrew (URL exacta la imprime `scripts/setup-userbrew.sh`). Sin estas credenciales el botón Google no aparece (degradación elegante).

### 4.6 Migración de usuarios

- `scripts/migrate-users-to-userbrew/main.go`:
  - Lee `users` de MongoDB; por cada uno crea usuario en userbrew vía API admin (`userbrew-sdk-go`), autenticada con API key admin (`USERBREW_ADMIN_TOKEN`).
  - Sin contraseña: quedan aptos para el recovery flow del hosted-ui, o para vincularse por email si entran con Google.
  - Flags: `--dry-run` (lista acciones sin ejecutar), `--skip-existing`.
  - Idempotente por email.

## 5. Variables de entorno nuevas

| Var | Dónde | Default |
|---|---|---|
| `USERBREW_ISSUER` | backend Go, frontends | `http://localhost:8090` |
| `USERBREW_CLIENT_ID` | frontends (storefront/admin respectivamente) | — |
| `USERBREW_REDIRECT_URI` | frontends | `http://localhost:{3000\|3100}/auth/callback` |
| `USERBREW_PUBLIC_URL` | servicio userbrew | `http://localhost:8090` |
| `GOOGLE_CLIENT_ID/SECRET` | servicio userbrew | vacío → Google deshabilitado |
| `USERBREW_ADMIN_TOKEN` | script migración | — |

## 6. Manejo de errores

- Callback con `error` (usuario cancela/Google falla): pantalla con mensaje claro + botón reintentar.
- Exchange fallido: snackbar + regreso a login; state PKCE inválido → error explícito.
- Token expirado en backend → 401 estándar; frontend intenta refresh si hay refresh_token, si no → logout limpio.
- JWKS inaccesible al arrancar → retry con backoff; requests mientras tanto → 503 en rutas protegidas.
- Google sin configurar → hosted-ui oculta el botón (comportamiento de userbrew); nada que manejar en app.

## 7. Testing

- **Go unitarios**: middleware con RSA test keys + JWKS falso (acepta/rechaza/expirado/aud incorrecto/kid desconocido→refetch). Upsert de usuarios con mongo de integración (tag build).
- **Flutter**: tests de `OidcAuthService` con http mock: generación PKCE determinista (verifier→challenge), manejo de callback success/error, roundtrip de persistencia.
- **Script migración**: `--dry-run` verificado contra fixture; integración real behind env flag.
- **E2E manual**: checklist (login password, login Google, registro, logout, acceso admin, compra completa autenticada).

## 8. Fuera de alcance

- Sentinel/forward-auth (no se despliega).
- Renderer nativo Flutter de userbrew (hosted-ui únicamente).
- MFA/TOTP setup UI (quedará disponible vía hosted-ui cuando se habilite en userbrew).
- Forgot-password local (reemplazado por recovery flow de userbrew).
- Cambios en Conekta/checkout (fuera de auth).

## 9. Riesgos

- Puerto dev fijo obligatorio en Flutter web (documentarlo en README/dev.sh).
- Tokens en localStorage (web): XSS surface — mitigado con CSP en nginx del frontend (tarea incluida en plan).
- Dependencia de userbrew en runtime: compose con healthcheck + restart policy; el catálogo/carrito anónimo sigue funcionando sin login.
