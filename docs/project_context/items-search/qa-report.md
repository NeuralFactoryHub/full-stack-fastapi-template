# QA Report — items free-text search

## Verdict: PASS (all 8 design ACs and US-004/005/006 checks)

## Gates
| Gate | Result |
|---|---|
| backend `scripts/lint.sh` (mypy, ty, ruff check, ruff format) | PASS |
| frontend `bun run --filter frontend lint` (biome) | PASS, no fixes applied |
| frontend `bun run --filter frontend build` | PASS (only the usual >500 kB chunk warning) |

Note: `frontend/src/routeTree.gen.ts` was already modified before QA and is rewritten by the running Vite dev server; reverted with `git checkout`. Repo-level unit tests were not run (design: no tests by project rule).

## API (US-004) — curl, superuser + regular user
| AC | Result | Evidence |
|---|---|---|
| 1 Match title OR description, case-insensitive | PASS | `q=blue`/`BLUE` → Blue Mug (title), Red Chair (description "qa blue legs"), user's "BLUE own"; `q=legs` → Red Chair only |
| 2 count == filtered total | PASS | `q=blue` count=3 = 3 rows; `limit=1&q=blue` → count=3, data=1 |
| 3 `%` / `_` literal | PASS | `q=%25` → only "100% cotton" (count 1); `q=_` → only "under_score"; `q=100%25` → 1; `q=%25%25` → 0; `q=\` → 0 |
| 4 Ownership | PASS | regular user: `q=blue` → 1 (own item); cannot see others' `legs`, `%`, `_` (0); superuser sees all (3) |
| No q / empty / whitespace unfiltered | PASS | omitted, `q=`, `q=%20%20%20` → identical count 9 (superuser) / 1 (user) |
| q of 255 chars OK, 256 → 422 | PASS | 255 → 200; 256 → 422 |
| NUL byte → 422 | PASS | `q=%00` and `q=a%00b` → 422 |

## UI (US-005, US-006) — Playwright, own tab, Table view unless noted
| AC | Result | Evidence |
|---|---|---|
| 5/6 Debounce → URL `?q=` | PASS | typing "blue" at 60 ms/char: URL unchanged at 100 ms, `?q=blue` after ~600 ms; exactly 1 request (`skip=0&limit=100&q=blue`) |
| 5 Reload keeps q and field | PASS | reload → `?q=blue`, field "blue", 3 rows |
| 5 Back/forward | PASS | leave to Dashboard then Back → `/items?q=cats`, field "cats", 1 row (qa-1000 cats); Forward → `/`. In-page history is not stepped (navigation uses `replace: true`, as designed) |
| 6 Previous results visible while typing | PASS | MutationObserver: min row count never dropped below 3 during typing, 0 skeleton (`animate-pulse`) nodes |
| 8 Table ↔ Cards both filtered | PASS | `q=blue` Cards shows the same 3 items; tab switch keeps q |
| × and Esc clear | PASS | × → URL `/items`, field empty, 9 rows; Esc after `q=chair` → same |
| 7 No-results state | PASS | `No items match "zzzqq"` + "Clear search" in both Table and Cards; button → URL `/items`, field empty, 9 rows. Screenshot: `screens/qa-noresults.png` |
| Empty state w/o q unchanged | PASS | user with zero items: "You don't have any items yet / Add a new item to get started", no search-specific copy |
| Malformed URLs | PASS | `?q=%00` and 300-char q → field empty, list unfiltered (invalid q dropped); `?q[]=x` → unfiltered; `?q=123` → field "123", no-results state, URL normalised to `?q=%22123%22`; `?q=%25` → literal match 1 row; `?q=<b>` → text echoed escaped. No page errors, no error UI, no console errors |

## Observations (not failures)
- `?q=123` is rewritten in the address bar to `?q=%22123%22` (router JSON-encodes numeric-looking strings). Works, but a cosmetic URL change.
- Because search navigation uses `replace`, Back inside `/items` leaves the page rather than undoing the previous query (consistent with design).

## Cleanup
All `qa-` items and `qa-user@example.com` deleted; remaining data: the 2 pre-existing items. Untracked files from the UX reviewer (not mine) left untouched.
