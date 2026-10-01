#!/usr/bin/env bash
# SessionStart hook — surface Neural Factory harness context at session start,
# so every developer begins already oriented (no manual "read project.yml first").
# Part of the NF harness. See .claude/hooks/README.md.
#
# Output on stdout is injected into the session as additional context.
# Always exits 0: this hook informs, it never blocks.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)

# Resolve the project directory from the hook payload, fall back to $PWD.
CWD="$PWD"
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  C=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
  [ -n "$C" ] && CWD="$C"
fi

# Act only inside a project that has the NF harness installed.
[ -f "$CWD/.claude/SDLC.md" ] || [ -f "$CWD/.claude/project.yml" ] || exit 0

OUT=""
add() { OUT="${OUT}$1
"; }

add "## Neural Factory harness — session context"
add ""

# Current git branch.
if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BR=$(git -C "$CWD" branch --show-current 2>/dev/null || true)
  [ -n "$BR" ] && add "- Git branch: \`$BR\` (SDLC branching: \`feature/<service>-<topic>\` / \`fix/<service>-<issue-id>\`)."
fi

# Project configuration.
if [ -f "$CWD/.claude/project.yml" ]; then
  add "- Project config: \`.claude/project.yml\` present — read it for services, stacks, lint/build commands, and ClickUp settings."
else
  add "- \`.claude/project.yml\` is MISSING — run \`/project-init\` before feature work."
fi

# Most recently touched in-progress feature.
RECENT_J=$(ls -t "$CWD"/docs/project_context/*/journals/*.md 2>/dev/null | head -1 || true)
if [ -n "$RECENT_J" ]; then
  FEAT=$(basename "$(dirname "$(dirname "$RECENT_J")")")
  add "- In-progress feature: \`$FEAT\` — see \`docs/project_context/$FEAT/\` (journals, validation reports)."
fi

# ClickUp sync state.
if [ -f "$CWD/docs/backlog/.clickup-sync.json" ]; then
  add "- ClickUp sync state: \`docs/backlog/.clickup-sync.json\` present — keep story status in sync (SDLC phases 6–8)."
fi

add ""
add "Follow \`.claude/SDLC.md\` for end-to-end feature delivery."

# Announce the hook ran and inject the context. JSON output lets us surface a
# persistent systemMessage alongside the SessionStart additionalContext;
# without jq we fall back to plain-text context (no announcement).
MSG="🪝 Neural Factory · load-context hook: session context loaded"
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$OUT" --arg msg "$MSG" \
    '{systemMessage: $msg,
      hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
else
  printf '%s' "$OUT"
fi
exit 0
