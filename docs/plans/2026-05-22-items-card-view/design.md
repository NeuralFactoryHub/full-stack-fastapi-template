# Design — Items Card View

- **Date:** 2026-05-22
- **ClickUp task:** [86c9xq200](https://app.clickup.com/t/86c9xq200) — "Vorrei che gli item siano visualizzati anche sotto forma di Card"
- **Author:** Walid Iguider
- **Status:** Draft

## 1. Problem statement

The Items page (`/items`) renders items only as a table (`DataTable`). Users
want an alternative **card grid** view. The table must remain available; a
toggle lets users switch and the choice persists across reloads.

## 2. Scope

- **In scope:** frontend-only. Table/Cards view toggle on the Items page,
  card grid rendering, `localStorage` persistence, card loading skeleton.
- **Non-goals:** backend/API changes, new data fields, filtering/sorting,
  client-side pagination for the card view.

## 3. Affected services

| Service  | Impact                                            |
|----------|---------------------------------------------------|
| backend  | None.                                             |
| frontend | New components + hook; `items.tsx` route modified.|

No OpenAPI schema change → **no client regeneration** needed. The
`frontend → backend` HTTP contract is untouched.

## 4. UX changes

- Items page header gains a segmented control (shadcn `Tabs` as the switch):
  `▤ Table` / `▦ Cards`, placed under the title/Add-Item row, right-aligned.
- **Default view: Table** — current behaviour unchanged on first visit.
- Card view: responsive grid — 1 col (mobile) / 2 (`sm`) / 3 (`lg`).
- Each card shows: `title` (CardTitle), `description` (CardDescription, italic
  "No description" fallback), copyable short ID (footer), and the existing
  `ItemActionsMenu` as `CardAction` (top-right).
- Empty state ("You don't have any items yet") is shared by both views.
- Loading: table keeps `PendingItems`; card view gets a card skeleton grid.

## 5. Component design

New files under `frontend/src/`:

| File                                    | Responsibility                          |
|-----------------------------------------|-----------------------------------------|
| `hooks/useLocalStorage.ts`              | Generic `localStorage`-backed state.    |
| `components/Items/ItemCard.tsx`         | Single item card (title/desc/id/actions).|
| `components/Items/ItemsGrid.tsx`        | Responsive grid of `ItemCard`.          |
| `components/Pending/PendingItemsGrid.tsx` | Card skeleton grid for the card view. |

Modified:

| File                                | Change                                       |
|--------------------------------------|----------------------------------------------|
| `routes/_layout/items.tsx`           | View state + `Tabs` switch + conditional render.|

**View state:** `useLocalStorage<"table" \| "cards">("items-view", "table")`.
The `Tabs` component is controlled (`value` / `onValueChange`), so the switch
and persistence stay in sync. Render is a conditional (`view === "cards"`),
not `TabsContent`, to keep the existing `Suspense`/empty-state flow intact.

**Reuse:** `Card*` primitives, `ItemActionsMenu`, `CopyId` pattern from
`columns.tsx` (extract the `CopyId` helper so table and card share it).

## 6. Data flow

Unchanged. `items.tsx` keeps the single `ItemsService.readItems({skip:0,
limit:100})` Suspense query; both views consume the same `items.data` array.

## 7. Risks & rollout

- **Low risk:** additive, frontend-only, no contract change. Worst case the
  toggle/grid misbehaves — table view (default) remains the safe fallback.
- **Rollback:** revert the frontend commit; no migrations, no env vars.
- **`localStorage` edge case:** SSR-safe guard not needed (Vite SPA, client
  only); the hook still guards against unavailable/throwing `localStorage`.
- **Observability:** none required (no new network/API surface).

## 8. Quality gates

- `bun run lint` (Biome) and `bun run build` (`tsc` + `vite build`) green.
- Manual check both views, toggle, reload persistence, empty state.

## Open questions

None.
