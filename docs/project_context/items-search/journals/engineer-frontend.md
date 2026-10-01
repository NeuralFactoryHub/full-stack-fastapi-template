# Engineer Journal — items-search (frontend, Tasks 3-4)
## Skill: frontend-react (plan code verbatim)
## Service: frontend/
## Plan: docs/plans/2026-10-01-items-search/plan.md

### Work Log

#### [10:05] Task 3: useDebouncedCallback
**What:** Created frontend/src/hooks/useDebouncedCallback.ts exactly as in the plan. It debounces the callback rather than a value, so an external URL change (back button) cannot re-fire an effect that pushes stale text back into the URL.
**Why:** The plan specifies this to keep URL and input in sync without feedback loops.
**Alternatives considered:** A debounced-value hook was rejected in the plan for the reason above.
**Files touched:** frontend/src/hooks/useDebouncedCallback.ts

#### [10:15] Task 4: SearchItems component
**What:** Created frontend/src/components/Items/SearchItems.tsx as in the plan, with one deviation: the wrapper `<div role="search">` became `<search className="relative block ...">`.
**Why:** Biome's lint/a11y/useSemanticElements flagged the role; the native `<search>` element is equivalent (landmark role search) and passes tsc. `block` is added because `<search>` is display:block only in modern UA stylesheets, and it keeps layout deterministic.
**Alternatives considered:** A biome-ignore comment (rejected: the native element is cleaner).
**Files touched:** frontend/src/components/Items/SearchItems.tsx

No tests written (project rule). node_modules was missing; ran `bun install` at the worktree root.

#### [10:40] Task 5: Items route wiring
**What:** Replaced frontend/src/routes/_layout/items.tsx with the plan's version, reformatted by biome: zod `validateSearch` for `q`, query key `["items", { q }]`, `useDeferredValue` so a refetch keeps the previous results visible, `NoSearchResults` with a "Clear search" button, and `SearchItems` in the toolbar next to the view Tabs.
**Why:** Keeping the `["items"]` prefix means existing create/edit/delete invalidations still hit the search queries. `Route.useNavigate()` exists in the installed @tanstack/react-router 1.163.3, so the `useNavigate({ from })` fallback was not needed.
**Alternatives considered:** The explicit validator return type from the plan was not needed since tsc raised no error on `Link to="/items"` in AppSidebar.
**Files touched:** frontend/src/routes/_layout/items.tsx

#### [10:50] Task 6: Gates
**What:** `bun run lint` (biome --write --unsafe) fixed one file, which is the formatting of items.tsx (no other file changed). `bun run build` (tsc + vite) succeeded. The build regenerated src/routeTree.gen.ts with only a route-order reshuffle, unrelated to this feature, so I reverted it with git checkout.
**Why:** Keeping the diff limited to the feature avoids noise in the commit.
**Files touched:** none beyond Task 5.

#### [11:30] Review fixes (Gandalf)
**What:** (1) items.tsx search schema now accepts string|number, coerces to string, trims and caps at 255, with `.catch(undefined)`, so `?q=` over 255 chars or `?q=123` no longer crashes via a 422 or a type mismatch; the empty-state branch therefore sees the trimmed q. `maxLength={255}` was added on the Input. (2) SearchItems replaced the trim-based sync with a `lastSent` ref: the debounced callback records what it sent, the sync effect ignores its own echo, and `clear()` sets `lastSent` to "" before `onSearch("")`. (3) Focus: `clear()` focuses the input, and `SearchItems` takes a `ref` prop (React 19) merged with an internal ref; Items passes `searchRef` and `clearSearch` focuses it, so the "Clear search" button in the empty state returns focus to the input. (4) Added a live region in ItemsContent announcing the result count or "No items match" only when a search is active (my call: no announcement without a query, to avoid noise on every refetch). (5) Esc ignores IME composition via `!e.nativeEvent.isComposing`.
**Why:** Each item comes straight from the review; the lastSent approach fixes the race where a stale echo of an earlier debounced value overwrote newer typing.
**Alternatives considered:** Keeping the trim comparison was rejected since it cannot tell our echo from an external change.
**Deviation:** The live region uses `<output className="sr-only">` instead of `<p role="status">` because Biome's useSemanticElements rejected the role; `<output>` has an implicit status role.
**Files touched:** frontend/src/routes/_layout/items.tsx, frontend/src/components/Items/SearchItems.tsx

#### [12:10] Review round 2 (Gandalf)
**What:** The search schema in items.tsx now also refuses strings containing a NUL (`.refine((s) => !s.includes("\0"))` inside the pipe, no regex to avoid Biome's noControlCharactersInRegex), so `?q=%00` falls back to no search instead of a backend error. The status message uses `items.count` (the total) instead of `items.data.length`. In SearchItems the `lastSent` ref became a `Set<string>` of every value sent (debounced callback and `clear()`), initialised with the initial value: the sync effect treats a URL value found in the set as our own echo and skips it, otherwise it clears the set, re-seeds it with the external value, cancels the pending debounce and sets the text.
**Why:** A single lastSent value broke when two echoes were in flight (type "ab", the router echoes "a" after "ab" was sent); the set tolerates out-of-order echoes.
**Accepted trade-off:** The number coercion means a hand-written `?q=1e3` becomes "1000" and `?q=1.0` becomes "1". Values typed in the box are quoted by the router, so only hand-written links are affected.
**Files touched:** frontend/src/routes/_layout/items.tsx, frontend/src/components/Items/SearchItems.tsx

#### [12:40] Review round 3 (Gandalf): Set replaced by a consumed queue
**What:** SearchItems now keeps `sent`, an ordered array of values pushed to the URL and not yet echoed back, with no initial seed. `valueRef` always holds the current URL value (assigned during render, Biome accepted it). The debounced callback skips a send equal to `valueRef.current` (the URL would not change, so no echo would ever come to consume it) and otherwise pushes and calls `onSearch`. The sync effect looks `value` up in the queue: found means our own echo, so drop it and everything older and return; not found means an external change, so empty the queue, cancel the debounce and set the text. `clear()` cancels, empties the text, focuses, and only when the URL value is non-empty queues "" and calls `onSearch("")`.
**Why:** The seeded Set was never emptied, so a later external navigation to a value that was ever sent looked like an echo and left stale text in the input.
**Scenarios checked mentally:**
- Typing "mug": after the debounce "mug" is queued, the URL echoes "mug", the effect consumes it and the text is untouched. Fast typing "m","mu": echoes arrive in order and each one drops itself and the older ones.
- Empty-state Clear: the route sets q to undefined, so value is "" and is not in the queue (it was consumed), so it counts as external and the text is cleared.
- Sidebar link to /items while q is active: value becomes "", external, text cleared.
- Back/forward to a previously sent value: that value was consumed from the queue on its first echo, so it counts as external and the text follows the URL.
- × clear: the text is emptied at once and "" is queued; the echo "" consumes it. If the URL was already "" nothing is queued.
- Esc: same path as ×.
- "mug " with the URL already "mug": the trimmed value equals valueRef, so nothing is sent and nothing is queued; the text keeps the trailing space.
**Files touched:** frontend/src/components/Items/SearchItems.tsx

#### [13:10] Polish round
**What:** (1) The dimmed wrapper uses `opacity-75` instead of `opacity-60` for better dark-mode contrast. (2) The live region moved out of ItemsContent into a new `SearchStatus` sibling rendered after the `aria-busy` div, in the same position in every branch. It calls `useQuery(getItemsQueryOptions(deferredQ))`, which reads the same cache entry as the list without suspending, and renders an empty message until data exists. (3) The Input has `enterKeyHint="search"` and `autoComplete="off"` (type stays text). (4) The no-op check in the debounced callback and in `clear()` now compares against `pendingTarget()`, the last queued value or else the current URL value, so a send that would repeat a queued one is skipped. (5) `valueRef` is assigned in a `useLayoutEffect` instead of during render.
**Why:** Putting the status in a sibling removes it from the busy subtree, so screen readers announce it right away; a non-suspense query was the simplest way to give it the count without lifting state or a callback.
**Alternatives considered:** Lifting the count through a callback from ItemsContent, rejected as more wiring and a render-time state update.
**Deviation:** The suggested `sent.current.at(-1)` fails tsc (TS2550, the lib target has no `Array.prototype.at`), so `pendingTarget()` indexes the last element by hand.
**Files touched:** frontend/src/routes/_layout/items.tsx, frontend/src/components/Items/SearchItems.tsx
