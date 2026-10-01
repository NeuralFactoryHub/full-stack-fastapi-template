---
name: sync-to-global
description: Copy this project's Claude harness (agents, commands, hooks, skills, SDLC.md, settings.json) into ~/.claude, with backups. Merges settings.json and rewrites hook paths so the harness works in every project.
---

Promote this project's Claude harness to the global config dir
(`${CLAUDE_CONFIG_DIR:-~/.claude}`) so it is available in every project.

## What it copies

From the project `.claude/` into the global config dir:

- `agents/`, `commands/`, `hooks/`, `skills/` — **merged** (existing files
  overwritten, extra files already in the dest are kept).
- `SDLC.md`.
- `settings.json` — **merged** into the existing global settings (project values
  win; `permissions.allow`/`deny`, `additionalDirectories` and
  `enabledMcpjsonServers` are unioned & de-duped so your global grants survive).
  Hook commands are rewritten from `$CLAUDE_PROJECT_DIR/.claude/hooks` to
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks` so hooks resolve to the global copy
  in every project.

Anything overwritten is first backed up to
`~/.claude/backups/global-sync-<timestamp>/`.

## Process

1. **Preview first.** Run `bash .claude/scripts/sync-to-global.sh --dry-run` and
   show the user what would change — in particular the merged `settings.json`.
2. On confirmation, run `bash .claude/scripts/sync-to-global.sh`.
3. Report the backup directory and the list of copied items.

## Notes

- Requires `jq` (for the settings merge).
- After syncing, the project hooks (load-context, protect-paths, format-code,
  check-journal) run in **every** project. If that is not wanted, edit the global
  `settings.json` afterwards — see `.claude/hooks/README.md`.
- Re-running is safe (idempotent): copies overwrite, permission arrays de-dupe,
  hook events are replaced not duplicated.
- `settings.local.json` is per-machine and is intentionally **not** copied.
