#!/usr/bin/env bash
# Stop hook — "journal & self-reflection" prompt.
# When a session changed code but no SDLC journal was updated, prompt the agent
# to (1) journal what/why/alternatives and (2) run a short self-reflection that
# proposes concrete CLAUDE.md / skill edits for whatever the session revealed,
# while context is still fresh (SDLC phases 6 & 10). See .claude/hooks/README.md.
#
# Blocks the stop exactly once (guarded by stop_hook_active) so the reminder is
# seen; it never loops. If the work was not SDLC feature work the agent can
# acknowledge and stop on the next turn.
set -uo pipefail

INPUT=$(cat 2>/dev/null || true)
command -v jq >/dev/null 2>&1 || exit 0

# Already re-entered after a previous block → let the session stop.
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)
[ "$STOP_ACTIVE" = "true" ] && exit 0

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -n "$CWD" ] || CWD="$PWD"

# Act only inside an NF harness project that is a git repo.
[ -f "$CWD/.claude/SDLC.md" ] || exit 0
git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Did this session change application code? (ignore docs/, .claude/, prose files)
CODE_CHANGES=$(git -C "$CWD" status --porcelain 2>/dev/null \
  | sed 's/^...//' \
  | grep -vE '^(docs/|\.claude/)' \
  | grep -vE '\.(md|markdown|txt)$' \
  | head -1 || true)
[ -n "$CODE_CHANGES" ] || exit 0

# Was an SDLC journal updated in the last 3 hours?
RECENT_JOURNAL=$(find "$CWD/docs/project_context" -path '*/journals/*.md' -mmin -180 2>/dev/null | head -1 || true)
[ -z "$RECENT_JOURNAL" ] || exit 0

REASON=$(cat <<'EOF'
NF SDLC reminder — code changed but no journal under docs/project_context/<feature>/journals/ was updated recently.

Before finishing, while context is still fresh, run a short self-reflection (SDLC phases 6 & 10):

  1. JOURNAL — record what / why / alternatives considered in the engineer journal.

  2. REFLECT — review what this session revealed about the codebase. For each
     point below, if the answer is yes, propose a CONCRETE edit (the target
     file plus the exact text to add/change), then apply it once confirmed:
       - A convention, gotcha, or constraint that was not documented?
         -> propose an edit to the relevant service CLAUDE.md (keep it lean).
       - A reusable pattern or recurring workflow worth capturing?
         -> propose an edit to the relevant skill under .claude/skills/.
       - An instruction in a CLAUDE.md or skill that proved stale or wrong?
         -> propose its removal or correction.
     If nothing emerged, state "no harness updates needed" explicitly.

  3. CARRY OVER — capture any lessons learned for the post-release feedback loop.

If this session was not SDLC feature work, acknowledge this and stop.
EOF
)

# JSON output blocks the stop once (the stop_hook_active guard above prevents a
# loop): `reason` instructs the agent, `systemMessage` announces to the user
# that the check-journal hook fired.
jq -n --arg r "$REASON" \
  '{decision: "block",
    reason: $r,
    systemMessage: "🪝 Neural Factory · check-journal hook: code changed without a recent journal entry — prompting journal & self-reflection"}'
exit 0
