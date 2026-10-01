# Engineer Journal — items-search (frontend, Tasks 3-4)
## Skill: frontend-react (plan code verbatim)
## Service: frontend/
## Plan: docs/plans/2026-10-01-items-search/plan.md

### Work Log

#### [now] Task 3: useDebouncedCallback
**What:** Created frontend/src/hooks/useDebouncedCallback.ts exactly as in the plan. It debounces the callback rather than a value, so an external URL change (back button) cannot re-fire an effect that pushes stale text back into the URL.
**Why:** The plan specifies this to keep URL and input in sync without feedback loops.
**Alternatives considered:** A debounced-value hook was rejected in the plan for the reason above.
**Files touched:** frontend/src/hooks/useDebouncedCallback.ts

#### [now] Task 4: SearchItems component
**What:** Created frontend/src/components/Items/SearchItems.tsx as in the plan, with one deviation: the wrapper `<div role="search">` became `<search className="relative block ...">`.
**Why:** Biome's lint/a11y/useSemanticElements flagged the role; the native `<search>` element is equivalent (landmark role search) and passes tsc. `block` is added because `<search>` is display:block only in modern UA stylesheets, and it keeps layout deterministic.
**Alternatives considered:** A biome-ignore comment (rejected: the native element is cleaner).
**Files touched:** frontend/src/components/Items/SearchItems.tsx

No tests written (project rule). node_modules was missing; ran `bun install` at the worktree root.

#### [later] Task 5: Items route wiring
**What:** Replaced frontend/src/routes/_layout/items.tsx with the plan's version verbatim: zod `validateSearch` for `q`, query key `["items", { q }]`, `useDeferredValue` so a refetch keeps the previous results visible, `NoSearchResults` with a "Clear search" button, and `SearchItems` in the toolbar next to the view Tabs.
**Why:** Keeping the `["items"]` prefix means existing create/edit/delete invalidations still hit the search queries. `Route.useNavigate()` exists in the installed @tanstack/react-router 1.163.3, so the `useNavigate({ from })` fallback was not needed.
**Alternatives considered:** The explicit validator return type from the plan was not needed since tsc raised no error on `Link to="/items"` in AppSidebar.
**Files touched:** frontend/src/routes/_layout/items.tsx

#### [later] Task 6: Gates
**What:** `bun run lint` (biome --write --unsafe) fixed one file, which is the formatting of items.tsx (no other file changed). `bun run build` (tsc + vite) succeeded. The build regenerated src/routeTree.gen.ts with only a route-order reshuffle, unrelated to this feature, so I reverted it with git checkout.
**Why:** Keeping the diff limited to the feature avoids noise in the commit.
**Files touched:** none beyond Task 5.
