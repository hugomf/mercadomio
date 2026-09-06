# Verification Checklist

Run through this checklist before declaring work complete. Commands are scoped to the actual layout of this repo (`backend` Go module, `frontend`/`admin_console` Flutter apps).

## Backend (Go)

Run from `backend/`:

- [ ] **Build**: `go build ./...` completes with zero errors
- [ ] **Static analysis**: `go vet ./...` completes with acceptable warnings only
- [ ] **Formatting**: `gofmt -l .` shows no files needing formatting (empty output)
- [ ] **Unit tests**: `go test ./services/` — all pass (currently 19)
- [ ] **Integration tests compile**: `go vet ./tests/` — clean, so live-Mongo tests stay compilable

> Integration tests in `backend/tests/` require a running MongoDB (`mongodb://localhost:27017`) and are expected to be skipped/failing when Mongo is down. Compile/vet cleanliness is the gate when Mongo is unavailable locally.

## Frontend (Flutter)

Run from `frontend/` and `admin_console/`:

- [ ] **Analyze**: `flutter analyze` reports no errors
- [ ] **Unit/widget tests**: `flutter test` passes

## Deploy / Docker

- [ ] **Dockerfile builds**: `docker build ./backend` succeeds; runtime image includes `curl`
      (required by the prod compose healthcheck) and runs as non-root `appuser`
- [ ] **Deploy scripts parse**: `bash -n deploy/setup-pi-production.sh`,
      `bash -n scripts/publish-images.sh`, and (from the shared engine repo)
      `bash -n lib/common.sh deploy.sh` all exit 0
- [ ] **Shared engine dry-run**: `sonnora-deploy/deploy.sh --project mercadomio --env {dev|qa|prod} --dry-run`
      completes exit 0 (preflight + staging + health steps printed, no SSH executed)
- [ ] **env files source cleanly**: `set -a; source deploy/env/dev.env; set +a` (and qa/prod)
      exit 0 with no errors
- [ ] **Compose valid**: `docker compose -f docker/docker-compose.yml config --quiet`
      and the QA variant pass (backend `.env` missing is OK — `env_file` is optional)
- [ ] **Prod artifacts**: sandbox dry-run of `setup-pi-production.sh` generation functions
      produces a compose that passes `docker compose config --quiet`; healthcheck URL is
      `/health` (not `/api/health`); mongo command has no `--smallfiles`
- [ ] **GHCR images published**: after pushing to `master`, the
      `.github/workflows/docker-publish.yml` workflow pushes
      `ghcr.io/hugomf/mercadomio/{backend,frontend}:latest` (production pulls these)

## Exit Criteria

- No new compilation, vet, or formatting failures introduced.
- All unit tests related to changed code pass.
- No unused imports or dead code (YAGNI / `gofmt` gates in DEV_GUIDELINES.md).
- Documentation updated for any user-facing changes (SESSION_LOG.md after each significant change).