# Hooks — the self-improving layer

Hooks are the fourth layer of the harness (alongside `agents/`, `commands/`,
`skills/`). Where agents and skills *advise* Claude, hooks **act
deterministically** at fixed points in the session lifecycle — they run
whether or not Claude remembers to.

They are wired in `.claude/settings.json` under the `hooks` key, so every
developer who has the harness inherits them.

## The hooks

| Event | Script | What it does |
|---|---|---|
| `SessionStart` | `load-context.sh` | Surfaces NF context at session start — git branch, `project.yml` status, in-progress feature, ClickUp sync state. Every session begins oriented. |
| `PreToolUse(Write\|Edit)` | `protect-paths.sh` | Blocks writes to generated / build / dependency dirs, lock files, generated-artifact names (`*.gen.*`, protobuf, minified bundles), and any file whose header carries a `DO NOT EDIT` / `@generated` marker — pointing the agent back to the real source. Project-agnostic. |
| `PostToolUse(Write\|Edit)` | `format-code.sh` | Formats the touched file with the formatter the project itself uses — detected from its config files (Biome / dprint / deno / Prettier / ESLint for JS/TS & friends, `ruff` or `black` for Python, `gofmt`/`rustfmt` for Go/Rust). Project-agnostic; replaces "remember to lint". |
| `Stop` | `check-journal.sh` | If code changed but no SDLC journal was updated, prompts the agent to journal **and run a short self-reflection** — proposing concrete CLAUDE.md / skill edits for any convention, pattern, or stale instruction the session revealed (SDLC phases 6 & 10). |

These map directly to the improvement plan (`Piano_Miglioramento_SDLC.md` §3.1):
a start hook that loads context, a stop hook for journal & memory, and
deterministic quality hooks.

## Announcements

Every hook announces itself, so it is always visible that the Neural Factory
harness layer is active. Every message is prefixed `🪝 Neural Factory · <hook>`:

- **While running** — a transient `statusMessage` (configured in
  `settings.json`) shows a `🪝 Neural Factory · <hook> running...` spinner on
  every invocation.
- **After a substantive action** — the script emits a JSON `systemMessage`
  that persists in the transcript: `load-context` confirms the session context
  was loaded, `format-code` reports `reformatted X` / `checked X (no changes)`,
  `protect-paths` reports the blocked write, and `check-journal` reports the
  journal reminder. Hooks that no-op stay silent beyond the spinner.

## Design rules

- **Fail open.** Every script exits `0` when a prerequisite is missing (`jq`
  not installed, not an NF project, not a git repo). A hook must never break a
  session.
- **NF-project-scoped.** Hooks act only when `.claude/SDLC.md` or
  `.claude/project.yml` is present, so they stay silent in unrelated repos —
  including the harness-source repo itself.
- **Auto-fix, don't gatekeep.** `format-code.sh` only applies safe fixes and
  never blocks. Lint *enforcement* remains with the `qa` agent (SDLC phase 8).
- **Block at most once.** `check-journal.sh` is guarded by `stop_hook_active`,
  so the reminder is seen exactly once and never loops.

## Requirements

- `bash` and `jq` on `PATH`. Without `jq`, hooks no-op silently.
- Optional, auto-detected per project: `format-code.sh` picks the formatter
  from the project's own config files (`biome.json`, `.prettierrc*`,
  `dprint.json`, `deno.json`, ESLint config; `ruff`/`black` for Python;
  `gofmt`/`rustfmt` for Go/Rust) and resolves the binary from
  `node_modules/.bin`, a project venv, or `PATH`. Missing tools are skipped —
  if a project configures no formatter, the hook stays silent.

Scripts are invoked as `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/scripts/<name>"`
— going through `bash` explicitly so the harness keeps working even if the
executable bit is lost during a manual per-project copy.

## Tuning / disabling

- To disable a hook, remove its block from `.claude/settings.json`.
- The generated-path lists in `protect-paths.sh` / `format-code.sh` and the
  `permissions.deny` list in `settings.json` are project-tunable — adjust them
  if a project legitimately uses a name like `build/` for source.

## Future: plugin packaging

When the harness is distributed as a Claude Code plugin
(`Piano_Miglioramento_SDLC.md` §3.6), this directory moves to a plugin
`hooks/hooks.json` and the command paths switch from `$CLAUDE_PROJECT_DIR` to
`$CLAUDE_PLUGIN_ROOT`.
