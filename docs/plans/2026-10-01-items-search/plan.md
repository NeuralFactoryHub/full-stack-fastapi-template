# Items Free-Text Search Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: use executing-plans skill to implement this plan task-by-task.

**Goal:** Let users filter the Items page by free text (title/description), server-side, with the query kept in the URL.

**Architecture:** `GET /items/` gains an optional `q` filtered with escaped `ILIKE` on both data and count queries. The frontend reads `q` from the route's validated search params, debounces typing into `navigate({ replace: true })`, and renders via `useDeferredValue(q)` so the previous results stay on screen while the new query suspends.

**Tech Stack:** FastAPI + SQLModel; React 19, TanStack Router (search params) + Query (suspense), zod 4, shadcn/ui, Biome.

**Design:** `docs/plans/2026-10-01-items-search/design.md` · **Stories:** `docs/backlog/user-stories-items-search-2026-10-01.md`

**Tests:** none (project rule — only on request). Verification = gates + QA walkthrough.

---

## Story → task map

| Story | ClickUp | Tasks |
|-------|---------|-------|
| US-004 API search | [123y1w8ga8h](https://app.clickup.com/t/123y1w8ga8h) | 1, 2 |
| US-005 Search UI | [123y1w8ga8k](https://app.clickup.com/t/123y1w8ga8k) | 3, 4, 5 |
| US-006 No-results state | [123y1w8ga8p](https://app.clickup.com/t/123y1w8ga8p) | 5 (empty state), 6 |

---

## Batch A — Backend (US-004)

### Task 1: Add `q` filter to `read_items`

Reference: @backend-python

**Files:**
- Modify: `backend/app/api/routes/items.py:1-45` (imports + `read_items`)

**Step 1: Update imports**

```python
from fastapi import APIRouter, HTTPException, Query
from sqlmodel import col, func, or_, select
```

**Step 2: Replace `read_items`** (dedupes the superuser/owner branches so the filter is applied once to both queries)

```python
@router.get("/", response_model=ItemsPublic)
def read_items(
    session: SessionDep,
    current_user: CurrentUser,
    skip: int = 0,
    limit: int = 100,
    q: str | None = Query(default=None, max_length=255),
) -> Any:
    """
    Retrieve items, optionally filtered by free text on title or description.
    """
    count_statement = select(func.count()).select_from(Item)
    statement = select(Item)

    if not current_user.is_superuser:
        count_statement = count_statement.where(Item.owner_id == current_user.id)
        statement = statement.where(Item.owner_id == current_user.id)

    term = q.strip() if q else ""
    if term:
        # Escape LIKE wildcards so user input matches literally.
        escaped = (
            term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        )
        pattern = f"%{escaped}%"
        search = or_(
            col(Item.title).ilike(pattern, escape="\\"),
            col(Item.description).ilike(pattern, escape="\\"),
        )
        count_statement = count_statement.where(search)
        statement = statement.where(search)

    count = session.exec(count_statement).one()
    items = session.exec(
        statement.order_by(col(Item.created_at).desc()).offset(skip).limit(limit)
    ).all()

    items_public = [ItemPublic.model_validate(item) for item in items]
    return ItemsPublic(data=items_public, count=count)
```

**Step 3: Lint**

```bash
cd backend && bash scripts/lint.sh
```

Expected: mypy, ty, ruff check and ruff format all pass. If `ruff format --check` fails, run `uv run ruff format app` and re-run.

### Task 2: Regenerate the API client

**Files:**
- Regenerated: `frontend/src/client/sdk.gen.ts`, `frontend/src/client/types.gen.ts`, `frontend/openapi.json` (never hand-edit)

**Step 1:** from repo root

```bash
bash scripts/generate-client.sh
```

**Step 2: Verify**

```bash
grep -n "q?:" frontend/src/client/types.gen.ts
grep -n "q: data.q" frontend/src/client/sdk.gen.ts
```

Expected: `ItemsReadItemsData` has `q?: (string | null);` and `readItems` passes `q: data.q`.

**Commit (Batch A):** `feat(backend): add free-text q filter to items list` (backend + regenerated client).

---

## Batch B — Frontend (US-005, US-006)

Reference: @frontend-nextjs (React/shadcn patterns; no react-vite skill yet)

### Task 3: Debounced-callback hook

Debouncing the *callback* (not the value) avoids an effect that re-fires when the URL changes externally (back button) and would push the stale text back into the URL.

**Files:**
- Create: `frontend/src/hooks/useDebouncedCallback.ts`

```ts
import { useCallback, useEffect, useRef } from "react"

export function useDebouncedCallback<Args extends unknown[]>(
  callback: (...args: Args) => void,
  delay: number,
) {
  const callbackRef = useRef(callback)
  const timeoutRef = useRef<ReturnType<typeof setTimeout>>(undefined)

  useEffect(() => {
    callbackRef.current = callback
  })

  const cancel = useCallback(() => clearTimeout(timeoutRef.current), [])

  useEffect(() => cancel, [cancel])

  const debounced = useCallback(
    (...args: Args) => {
      cancel()
      timeoutRef.current = setTimeout(() => callbackRef.current(...args), delay)
    },
    [cancel, delay],
  )

  return { debounced, cancel }
}
```

### Task 4: `SearchItems` component

**Files:**
- Create: `frontend/src/components/Items/SearchItems.tsx`

```tsx
import { Search, X } from "lucide-react"
import { useEffect, useState } from "react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useDebouncedCallback } from "@/hooks/useDebouncedCallback"

interface SearchItemsProps {
  value: string
  onSearch: (q: string) => void
}

export function SearchItems({ value, onSearch }: SearchItemsProps) {
  const [text, setText] = useState(value)
  const { debounced, cancel } = useDebouncedCallback(onSearch, 300)

  // Follow external URL changes (back/forward, "Clear search" in the empty
  // state) without clobbering trailing whitespace the user is still typing.
  useEffect(() => {
    setText((current) => (current.trim() === value ? current : value))
  }, [value])

  const clear = () => {
    cancel()
    setText("")
    onSearch("")
  }

  return (
    <div role="search" className="relative w-full sm:max-w-xs">
      <Search
        aria-hidden="true"
        className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
      />
      <Input
        value={text}
        onChange={(e) => {
          setText(e.target.value)
          debounced(e.target.value.trim())
        }}
        onKeyDown={(e) => {
          if (e.key === "Escape" && text) {
            e.preventDefault()
            clear()
          }
        }}
        placeholder="Search items…"
        aria-label="Search items"
        className="pl-8 pr-9"
      />
      {text && (
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label="Clear search"
          onClick={clear}
          className="absolute right-0.5 top-1/2 size-8 -translate-y-1/2"
        >
          <X />
        </Button>
      )}
    </div>
  )
}
```

### Task 5: Wire search into the Items route + no-results state

**Files:**
- Modify: `frontend/src/routes/_layout/items.tsx` (whole file)

```tsx
import { useSuspenseQuery } from "@tanstack/react-query"
import { createFileRoute } from "@tanstack/react-router"
import { LayoutGrid, Search, Table2 } from "lucide-react"
import { Suspense, useCallback, useDeferredValue } from "react"
import { z } from "zod"

import { ItemsService } from "@/client"
import { DataTable } from "@/components/Common/DataTable"
import AddItem from "@/components/Items/AddItem"
import { columns } from "@/components/Items/columns"
import { ItemsGrid } from "@/components/Items/ItemsGrid"
import { SearchItems } from "@/components/Items/SearchItems"
import PendingItems from "@/components/Pending/PendingItems"
import PendingItemsGrid from "@/components/Pending/PendingItemsGrid"
import { Button } from "@/components/ui/button"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useLocalStorage } from "@/hooks/useLocalStorage"
import { cn } from "@/lib/utils"

type ItemsViewMode = "table" | "cards"

const itemsSearchSchema = z.object({
  q: z.string().optional().catch(undefined),
})

function getItemsQueryOptions(q: string) {
  return {
    queryFn: () =>
      ItemsService.readItems({ skip: 0, limit: 100, q: q || undefined }),
    // Prefix ["items"] keeps existing invalidations (create/edit/delete) working.
    queryKey: ["items", { q }],
  }
}

export const Route = createFileRoute("/_layout/items")({
  component: Items,
  validateSearch: (search) => itemsSearchSchema.parse(search),
  head: () => ({
    meta: [
      {
        title: "Items - FastAPI Template",
      },
    ],
  }),
})

function EmptyItems() {
  return (
    <div className="flex flex-col items-center justify-center text-center py-12">
      <div className="rounded-full bg-muted p-4 mb-4">
        <Search className="h-8 w-8 text-muted-foreground" />
      </div>
      <h3 className="text-lg font-semibold">You don't have any items yet</h3>
      <p className="text-muted-foreground">Add a new item to get started</p>
    </div>
  )
}

function NoSearchResults({ q, onClear }: { q: string; onClear: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center text-center py-12">
      <div className="rounded-full bg-muted p-4 mb-4">
        <Search className="h-8 w-8 text-muted-foreground" />
      </div>
      <h3 className="text-lg font-semibold break-all">
        No items match "{q}"
      </h3>
      <p className="text-muted-foreground mb-4">Try a different search</p>
      <Button variant="outline" onClick={onClear}>
        Clear search
      </Button>
    </div>
  )
}

interface ItemsViewProps {
  view: ItemsViewMode
  q: string
  onClearSearch: () => void
}

function ItemsContent({ view, q, onClearSearch }: ItemsViewProps) {
  const { data: items } = useSuspenseQuery(getItemsQueryOptions(q))

  if (items.data.length === 0) {
    return q ? (
      <NoSearchResults q={q} onClear={onClearSearch} />
    ) : (
      <EmptyItems />
    )
  }

  return view === "cards" ? (
    <ItemsGrid items={items.data} />
  ) : (
    <DataTable columns={columns} data={items.data} />
  )
}

function ItemsView(props: ItemsViewProps) {
  return (
    <Suspense
      fallback={props.view === "cards" ? <PendingItemsGrid /> : <PendingItems />}
    >
      <ItemsContent {...props} />
    </Suspense>
  )
}

function Items() {
  const [view, setView] = useLocalStorage<ItemsViewMode>("items-view", "table")
  const { q = "" } = Route.useSearch()
  const navigate = Route.useNavigate()
  // Deferred so a suspending refetch keeps showing the previous results.
  const deferredQ = useDeferredValue(q)

  const setSearch = useCallback(
    (next: string) => {
      navigate({
        search: (prev) => ({ ...prev, q: next || undefined }),
        replace: true,
      })
    },
    [navigate],
  )
  const clearSearch = useCallback(() => setSearch(""), [setSearch])

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Items</h1>
          <p className="text-muted-foreground">Create and manage your items</p>
        </div>
        <AddItem />
      </div>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <SearchItems value={q} onSearch={setSearch} />
        <Tabs
          value={view}
          onValueChange={(value) => setView(value as ItemsViewMode)}
        >
          <TabsList>
            <TabsTrigger value="table">
              <Table2 />
              Table
            </TabsTrigger>
            <TabsTrigger value="cards">
              <LayoutGrid />
              Cards
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </div>
      <div
        className={cn(
          "transition-opacity",
          q !== deferredQ && "opacity-60",
        )}
        aria-busy={q !== deferredQ}
      >
        <ItemsView
          view={view}
          q={deferredQ}
          onClearSearch={clearSearch}
        />
      </div>
    </div>
  )
}
```

### Task 6: Frontend gates

```bash
cd frontend && bun run lint && bun run build
```

Expected: Biome clean (it auto-fixes formatting — re-stage), `tsc` + `vite build` succeed.
If `tsc` complains that `Link to="/items"` in `src/components/Sidebar/AppSidebar.tsx` now requires `search`, it means `q` is not inferred optional — fix the validator's return type (`(search): { q?: string } => …`), do not add `search` to the sidebar.

**Commit (Batch B):** `feat(frontend): add free-text search to items page`.

---

## After implementation

- ClickUp: US-004..006 → `in progress` at batch start; PR open → `in review`; merge → `Closed` (+ time entry).
- Hand off to review (Gandalf) → QA (Colombo, ACs 1–8 from design) → UX (Da Vinci).
