#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — deterministic, project-agnostic formatting of
# the touched file. Replaces "remember to ask Claude to lint".
#
# It does NOT assume a fixed toolchain. It detects the formatter the project
# actually uses — from the project's own config files — and runs that one on
# the single touched file:
#
#   JS / TS / JSON / CSS / ...  Biome | dprint | deno fmt | Prettier (+ ESLint)
#   Python                      ruff  | black (+ isort)
#   Go / Rust                   gofmt (+ goimports) | rustfmt
#
# Picking the formatter from config (not from "whatever binary exists") is
# deliberate: a Biome project must not be silently reformatted by Prettier.
# Auto-fixes only; it never blocks. Remaining lint findings stay with the `qa`
# agent (SDLC phase 8). Fails open. See .claude/hooks/README.md.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0

# Never touch files inside generated / build / dependency trees.
case "/$FILE/" in
  */node_modules/*|*/.next/*|*/.turbo/*|*/dist/*|*/build/*|*/out/*|\
  */.svelte-kit/*|*/__pycache__/*|*/.venv/*|*/venv/*|*/vendor/*|*/target/*)
    exit 0 ;;
esac

FILE_DIR=$(cd "$(dirname "$FILE")" 2>/dev/null && pwd) || exit 0

# --- detection & resolution helpers --------------------------------------
# Both walk up from the touched file, so a monorepo resolves each package's
# own config and dependencies independently.

# find_up <glob>: echo the first ancestor dir holding a match for <glob>.
# Unquoted glob expansion; with no match the literal stays and fails -e.
find_up() {
  local dir="$FILE_DIR" f
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    for f in "$dir"/$1; do
      [ -e "$f" ] && { printf '%s' "$dir"; return 0; }
    done
    dir=$(dirname "$dir")
  done
  return 1
}

# resolve_bin <tool>: echo a runnable path — nearest node_modules/.bin or a
# project venv (walking up), else a tool on PATH. Non-zero if unresolved.
resolve_bin() {
  local tool="$1" dir="$FILE_DIR" v
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    [ -x "$dir/node_modules/.bin/$tool" ] && {
      printf '%s' "$dir/node_modules/.bin/$tool"; return 0; }
    for v in .venv venv; do
      [ -x "$dir/$v/bin/$tool" ] && { printf '%s' "$dir/$v/bin/$tool"; return 0; }
    done
    dir=$(dirname "$dir")
  done
  command -v "$tool" 2>/dev/null && return 0
  return 1
}

# pkg_has_prettier: nearest package.json declares a top-level "prettier" key.
pkg_has_prettier() {
  local dir="$FILE_DIR"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/package.json" ]; then
      [ "$(jq -r 'has("prettier")' "$dir/package.json" 2>/dev/null)" = "true" ]
      return
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# eslint_configured: a flat or legacy ESLint config exists above the file.
eslint_configured() {
  find_up 'eslint.config.*' >/dev/null || find_up '.eslintrc*' >/dev/null
}

# --- formatters per language family --------------------------------------

DID=0      # flips to 1 once a formatter has actually run
TOOL=""    # human-readable name(s) of what ran, for the announcement

# JS/TS/JSON/CSS/markup family — pick the project's configured formatter.
format_js() {
  local bin
  # Biome — config is biome.json / biome.jsonc.
  if find_up 'biome.json' >/dev/null || find_up 'biome.jsonc' >/dev/null; then
    if bin=$(resolve_bin biome); then
      "$bin" check --write --no-errors-on-unmatched \
        --files-ignore-unknown=true "$FILE" >/dev/null 2>&1 || true
      TOOL=biome; DID=1; return
    fi
  fi
  # dprint — config is dprint.json / .dprint.json.
  if find_up 'dprint.json' >/dev/null || find_up '.dprint.json' >/dev/null; then
    if bin=$(resolve_bin dprint); then
      "$bin" fmt "$FILE" >/dev/null 2>&1 || true
      TOOL=dprint; DID=1; return
    fi
  fi
  # Deno — config is deno.json / deno.jsonc.
  if find_up 'deno.json' >/dev/null || find_up 'deno.jsonc' >/dev/null; then
    if bin=$(resolve_bin deno); then
      "$bin" fmt "$FILE" >/dev/null 2>&1 || true
      TOOL="deno fmt"; DID=1; return
    fi
  fi
  # Prettier — a .prettierrc* / prettier.config.* file, or a package.json key.
  if find_up '.prettierrc*' >/dev/null || find_up 'prettier.config.*' >/dev/null \
     || pkg_has_prettier; then
    if bin=$(resolve_bin prettier); then
      "$bin" --write "$FILE" >/dev/null 2>&1 || true
      TOOL=prettier; DID=1
    fi
  fi
  # ESLint --fix — complements Prettier, or stands alone if it is the only
  # config present. Lint-fix, not pure formatting, but safe and in-place.
  if eslint_configured; then
    if bin=$(resolve_bin eslint); then
      "$bin" --fix "$FILE" >/dev/null 2>&1 || true
      TOOL="${TOOL:+$TOOL+}eslint"; DID=1
    fi
  fi
}

# Python — ruff if available (sane defaults, no config needed), else black.
format_py() {
  local bin
  if bin=$(resolve_bin ruff); then
    "$bin" format "$FILE" >/dev/null 2>&1 || true
    "$bin" check --fix "$FILE" >/dev/null 2>&1 || true
    TOOL=ruff; DID=1; return
  fi
  if bin=$(resolve_bin black); then
    "$bin" "$FILE" >/dev/null 2>&1 || true
    TOOL=black; DID=1
  fi
  if bin=$(resolve_bin isort); then
    "$bin" "$FILE" >/dev/null 2>&1 || true
    TOOL="${TOOL:+$TOOL+}isort"; DID=1
  fi
}

# Go / Rust — toolchain formatters, resolved from PATH.
format_go() {
  local bin
  if bin=$(resolve_bin gofmt); then
    "$bin" -w "$FILE" >/dev/null 2>&1 || true
    TOOL=gofmt; DID=1
  fi
  if bin=$(resolve_bin goimports); then
    "$bin" -w "$FILE" >/dev/null 2>&1 || true
    TOOL="${TOOL:+$TOOL+}goimports"; DID=1
  fi
}
format_rust() {
  local bin
  if bin=$(resolve_bin rustfmt); then
    "$bin" "$FILE" >/dev/null 2>&1 || true
    TOOL=rustfmt; DID=1
  fi
}

# --- dispatch on file type -----------------------------------------------

EXT=$(printf '%s' "${FILE##*.}" | tr '[:upper:]' '[:lower:]')
BEFORE=$(shasum "$FILE" 2>/dev/null | awk '{print $1}')

case "$EXT" in
  js|jsx|mjs|cjs|ts|tsx|mts|cts|json|jsonc|css|scss|less|html|vue|svelte|\
  astro|md|mdx|yaml|yml|graphql|gql)
    format_js ;;
  py|pyi)  format_py ;;
  go)      format_go ;;
  rs)      format_rust ;;
esac

# No formatter ran (unknown type, or the project's tool is not installed) →
# nothing to announce; the transient statusMessage already showed the hook.
[ "$DID" = "1" ] || exit 0

NAME=$(basename "$FILE")
AFTER=$(shasum "$FILE" 2>/dev/null | awk '{print $1}')
if [ "$BEFORE" != "$AFTER" ]; then
  jq -n --arg n "$NAME" --arg t "$TOOL" \
    '{systemMessage: ("🪝 Neural Factory · format-code hook: reformatted " + $n + " (" + $t + ")")}'
else
  jq -n --arg n "$NAME" --arg t "$TOOL" \
    '{systemMessage: ("🪝 Neural Factory · format-code hook: checked " + $n + " (" + $t + ", no changes)")}'
fi
exit 0
