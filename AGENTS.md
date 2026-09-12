# AGENTS.md — Instrucciones para agentes de IA

## Seguridad de git (trabajo multi-agente)

Varios agentes pueden operar sobre este repo. Respeta los cambios de los demás:

- **NUNCA** ejecutes operaciones destructivas sin confirmación explícita del usuario:
  `git checkout <branch>`/`git checkout -- .`, `git stash`, `git reset --hard`,
  `git clean`, `git branch -D`, `git push --force`.
- Antes de cambiar de rama: revisa `git status` y `git diff`. Si hay cambios sin
  commit, NO los descartes ni los guardes en stash por tu cuenta: pregunta.
- Realiza commits pequeños y frecuentes con mensajes claros. No hagas squash ni
  amend de commits ajenos, ni rebase de trabajo compartido.
- `git checkout -b` (crear rama) y `git switch -c` son seguros; crear ramas para
  trabajo aislado es lo preferido.
- Para trabajo de feature, usa ramas de trabajo o worktrees aislados.

## Puertos de servicio

**REGLA ABSOLUTA:** Este host tiene muchas aplicaciones corriendo. NUNCA uses puertos comunes.

### Puertos PROHIBIDOS (jamás usar como default)

`80`, `443`, `3000`, `3001`, `3100`, `4000`, `5000`, `5173`, `5432`, `6379`, `8000`, `8001`, `8080`, `8081`, `8083`, `8084`, `8085`, `8090`, `9000`, `9090`, `27017`

### Asignación de puertos MercadoMío (rango 5200+)

| Servicio              | Puerto | Notas                                       |
|-----------------------|--------|---------------------------------------------|
| Backend (Go/Fiber)    | `5200` | host port en docker-compose; `PORT` en .env  |
| Storefront (Flutter)  | `5201` | `--web-port` en scripts/frontend.sh          |
| Admin Console         | `5202` | `--web-port` en scripts/admin-console.sh     |
| Nginx (proxy)         | `5203` | Solo para reverse proxy, nunca app directa   |
| Postgres              | `5210` | Host-mapped; container interno sigue en 5432 |
| MongoDB               | `5211` | Host-mapped; container interno sigue en 27017|
| Redis                 | `5212` | Host-mapped; container interno sigue en 6379 |
| RedisInsight          | `5213` | RedisInsight UI                              |

### Reglas

- **Nunca** uses un puerto de la lista "PROHIBIDOS" como default para nuevos servicios.
- Si necesitas un servicio nuevo, asigna el siguiente puerto libre en la secuencia 5216, 5217...
- Reserva `80`/`443` solo para proxies reversos o TLS termination (nginx, Caddy, etc.).
- Los puertos internos de containers (mongo:27017, redis:6379, etc.) se mantienen — solo cambia el **host-mapping**.

## Verificación

- Corre `flutter analyze` y `go vet`/`go build` y ejecuta los tests del área tocada
  antes de declarar completado. No afirmes que algo pasa sin ejecutarlo.