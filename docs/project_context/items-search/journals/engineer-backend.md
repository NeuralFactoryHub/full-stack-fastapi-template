# Engineer Journal — items-search (backend)
## Skill: backend-python
## Service: backend/
## Plan: docs/plans/2026-10-01-items-search/plan.md (Task 1)

### Work Log

#### [10:00] Task 1: Add `q` filter to `read_items`
**What:** Edited backend/app/api/routes/items.py: imports now include `Query` and `or_`; `read_items` takes an optional `q` (max_length 255) and builds one base statement per query, adding the owner filter for non-superusers and the search filter when the trimmed term is non-empty. The search is a case-insensitive LIKE on title or description, applied to both the count and the list query so `count` matches the filtered total.
**Why:** The plan dedupes the superuser/owner branches so the filter is written once. LIKE wildcards (`%`, `_`, `\`) are escaped so user input matches literally rather than acting as a pattern.
**Alternatives considered:** Full-text search or trigram index were out of scope for the design; a simple ilike is enough for the item volume.
**Deviations from plan:** None in logic. Only `ruff format` reflowed the `escaped = (...)` expression onto one line. No tests written, per lead's instruction (project rule given in the brief). backend/CLAUDE.md does not exist. Lint must run via `uv run bash scripts/lint.sh` (tools are not on PATH).
**Files touched:** backend/app/api/routes/items.py
