#!/usr/bin/env bash
#
# sync-to-global.sh — promote this project's Claude harness into the global
# config dir (~/.claude) so it is available in every project.
#
# Copies, with a timestamped backup of anything it would overwrite:
#   agents/  commands/  hooks/  skills/   (merged: existing files overwritten,
#                                          extra files in the dest are kept)
#   SDLC.md
#   settings.json  — MERGED into the existing global settings (project values
#                    win; permissions.allow/deny, additionalDirectories and
#                    enabledMcpjsonServers are unioned & de-duped). Hook command
#                    paths are rewritten from $CLAUDE_PROJECT_DIR/.claude/hooks
#                    to the global hooks dir so they resolve in every project.
#
# Re-running is safe (idempotent): copies overwrite, arrays de-dupe, hook events
# are replaced rather than duplicated.
#
# Usage: bash .claude/scripts/sync-to-global.sh [--dry-run]

set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# Source = the .claude/ dir this script lives in; Dest = the global config dir.
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$DEST_DIR/backups/global-sync-$TS"

DIRS=(agents commands hooks skills)
FILES=(SDLC.md)

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required for the settings.json merge (brew install jq)" >&2
  exit 1
}

echo "Source : $SRC_DIR"
echo "Dest   : $DEST_DIR"
echo "Backup : $BACKUP_DIR"
[ "$DRY_RUN" = 1 ] && echo "Mode   : DRY RUN — no changes are written"
echo

if [ "$DRY_RUN" = 0 ]; then
  mkdir -p "$DEST_DIR" "$BACKUP_DIR"
fi

# Back up an existing dest path before it is overwritten.
backup() {
  local rel="$1"
  [ -e "$DEST_DIR/$rel" ] || return 0
  if [ "$DRY_RUN" = 0 ]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    cp -R "$DEST_DIR/$rel" "$BACKUP_DIR/$rel"
  fi
  echo "  backed up existing $rel"
}

# --- directories (merge) ---------------------------------------------------
for d in "${DIRS[@]}"; do
  [ -d "$SRC_DIR/$d" ] || continue
  echo "✓ $d/"
  backup "$d"
  if [ "$DRY_RUN" = 0 ]; then
    mkdir -p "$DEST_DIR/$d"
    cp -R "$SRC_DIR/$d/." "$DEST_DIR/$d/"
  fi
done

# --- plain files -----------------------------------------------------------
for f in "${FILES[@]}"; do
  [ -f "$SRC_DIR/$f" ] || continue
  echo "✓ $f"
  backup "$f"
  if [ "$DRY_RUN" = 0 ]; then
    cp "$SRC_DIR/$f" "$DEST_DIR/$f"
  fi
done

# --- settings.json (merge + hook path rewrite) -----------------------------
if [ -f "$SRC_DIR/settings.json" ]; then
  echo "✓ settings.json (merge + hook path rewrite)"
  backup "settings.json"

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  # Rewrite hook commands so they point at the global hooks copy in any project.
  sed 's#\$CLAUDE_PROJECT_DIR/\.claude/hooks#${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks#g' \
    "$SRC_DIR/settings.json" > "$TMP/project.json"

  if [ -f "$DEST_DIR/settings.json" ]; then
    cp "$DEST_DIR/settings.json" "$TMP/global.json"
  else
    echo '{}' > "$TMP/global.json"
  fi

  # Deep-merge (project wins) but union the permission/MCP arrays so the user's
  # existing global grants are preserved rather than replaced.
  jq -s '
    def uc(a; b): ((a // []) + (b // [])) | unique;
    .[0] as $g | .[1] as $p |
    ($g * $p)
    | .permissions = (($g.permissions // {}) * ($p.permissions // {})
        | .allow = uc($g.permissions.allow; $p.permissions.allow)
        | .deny  = uc($g.permissions.deny;  $p.permissions.deny)
        | .additionalDirectories =
            uc($g.permissions.additionalDirectories; $p.permissions.additionalDirectories))
    | .enabledMcpjsonServers = uc($g.enabledMcpjsonServers; $p.enabledMcpjsonServers)
  ' "$TMP/global.json" "$TMP/project.json" > "$TMP/merged.json"

  if [ "$DRY_RUN" = 0 ]; then
    cp "$TMP/merged.json" "$DEST_DIR/settings.json"
  else
    echo "  [dry-run] merged settings.json would be:"
    sed 's/^/    /' "$TMP/merged.json"
  fi
fi

echo
if [ "$DRY_RUN" = 1 ]; then
  echo "Dry run complete — nothing written. Re-run without --dry-run to apply."
else
  echo "Done. Overwritten files were backed up to:"
  echo "  $BACKUP_DIR"
fi
