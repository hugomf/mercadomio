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

## Verificación

- Corre `flutter analyze` y `go vet`/`go build` y ejecuta los tests del área tocada
  antes de declarar completado. No afirmes que algo pasa sin ejecutarlo.