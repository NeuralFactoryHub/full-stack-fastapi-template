# Design: Items free-text search

**Source:** ClickUp task [123y1w8g9t9](https://app.clickup.com/t/123y1w8g9t9) — "Ricerca Items con testo libero"
**Date:** 2026-10-01
**Status:** Approved (brainstorm 2026-10-01)

## Problem

The Items page lists up to 100 items with no way to find one by text. Users
need to type a string and see only items whose title or description contains it.

## Decisions

| Topic | Decision | Rejected |
|-------|----------|----------|
| Where search runs | Server-side `q` param on `GET /items/`, `ILIKE` | Client-side filter (misses items >100); Postgres FTS (migration, overkill for 255-char fields) |
| Where search state lives | URL search param `/items?q=…` | Local state (lost on reload) |
| Tests | None (project rule: only on request); QA walks ACs | — |

## Affected services

- `backend` — `app/api/routes/items.py`
- `frontend` — `routes/_layout/items.tsx`, new `components/Items/SearchItems.tsx`, new `hooks/useDebounce.ts`
- `frontend/src/client/` — regenerated via `bash scripts/generate-client.sh`

## Backend

`GET /items/` gains `q: str | None = Query(None, max_length=255)`.

- `q` trimmed; empty/`None` → current behavior.
- Filter: `or_(col(Item.title).ilike(p, escape="\\"), col(Item.description).ilike(p, escape="\\"))`
  with `p = f"%{escaped}%"`; `\`, `%`, `_` escaped so they match literally.
- Applied to both data and `count` queries, for superuser and owner-scoped branches.
- Order (`created_at desc`), `skip`, `limit` unchanged. No migration, no index.

**Contract:** additive, non-breaking. Clients omitting `q` unaffected.

## Frontend / UX

- Route `validateSearch`: `z.object({ q: z.string().optional().catch(undefined) })`.
- Query options: key `["items", { q }]`, call `readItems({ skip: 0, limit: 100, q })`.
  Existing `["items"]` invalidations still match by prefix.
- `SearchItems`: `Input` + `Search` icon, placeholder "Search items…",
  `aria-label="Search items"`, left of the Table/Cards tabs. Local state →
  `useDebounce` (300 ms) → `navigate({ search, replace: true })` wrapped in
  `useTransition` so previous results stay visible (no skeleton flash).
  Clear button (`aria-label="Clear search"`) and Esc reset field and drop `q`.
  Field initialised from URL `q`.
- Empty states: with `q` active and no results → `No items match "{q}"` + "Clear search"
  button; without `q` → existing "You don't have any items yet".
- Table and Cards views receive the same filtered data; no change to `DataTable`/`ItemsGrid`.

## Acceptance criteria

1. `?q=` matches title or description, case-insensitive.
2. `count` reflects the filter.
3. `%` and `_` in `q` match literally.
4. Non-superuser only sees own items; superuser sees all.
5. `q` lives in the URL, survives reload/back; field pre-filled from URL.
6. Input debounced (~300 ms); previous results visible while refetching.
7. Distinct "no results" state with working "Clear search".
8. Table and Cards both reflect the filter.

## Verification

- Gates: backend `bash scripts/lint.sh`; frontend `bun run lint`, `bun run build`.
- QA (Colombo) walks ACs 1–8 on the running stack; UX review (Da Vinci) for
  labels, focus, contrast, mobile layout.

## Rollout / rollback

Single PR (backend + client + frontend). No migration, flag, or env var.
Rollback = revert PR.

## Risks

- `ILIKE '%x%'` → seq scan; fine at template scale. Mitigation if needed: `pg_trgm` + GIN.
- Missing escape → `q=%` matches everything; covered by AC 3.
- Stale client → build fails (guard, not silent bug).

## Non-goals

Ranking, fuzzy/typo tolerance, other fields (owner, date), match highlighting,
server-side pagination in the UI.
