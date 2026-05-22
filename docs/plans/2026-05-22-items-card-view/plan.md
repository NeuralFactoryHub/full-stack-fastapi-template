# Items Card View Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: use executing-plans skill to implement this plan task-by-task.

**Goal:** Add a card-grid view to the Items page with a Table/Cards toggle that persists the user's choice.

**Architecture:** Frontend-only. A new `useLocalStorage` hook backs a controlled shadcn `Tabs` segmented control in `items.tsx`. The route conditionally renders either the existing `DataTable` or a new `ItemsGrid` of `ItemCard`s — both consume the same Suspense query. No backend or API change.

**Tech Stack:** React 19, TanStack Router/Query, Tailwind CSS 4, shadcn/ui, Bun, Biome.

**Skill:** Reference `@frontend-nextjs` for React/Tailwind/shadcn patterns (ignore its Next.js routing — this is a Vite SPA with TanStack Router).

**Story mapping:** Task 1 → US-002 · Tasks 2-4 → US-001 · Task 5 → US-003 · Task 6 → US-001/US-002/US-003 · Task 7 → all.

---

### Task 1: `useLocalStorage` hook

**Files:**

- Create: `frontend/src/hooks/useLocalStorage.ts`

**Step 1: Implement the hook**

```typescript
import { useCallback, useState } from "react"

export function useLocalStorage<T>(
  key: string,
  initialValue: T,
): [T, (value: T) => void] {
  const readValue = useCallback((): T => {
    try {
      const item = window.localStorage.getItem(key)
      return item ? (JSON.parse(item) as T) : initialValue
    } catch {
      return initialValue
    }
  }, [key, initialValue])

  const [storedValue, setStoredValue] = useState<T>(readValue)

  const setValue = useCallback(
    (value: T) => {
      setStoredValue(value)
      try {
        window.localStorage.setItem(key, JSON.stringify(value))
      } catch {
        // localStorage unavailable — keep value in memory only
      }
    },
    [key],
  )

  return [storedValue, setValue]
}
```

**Step 2: Verify**

```bash
cd frontend && bun run lint
```

Expected: no Biome errors for the new file.

---

### Task 2: Extract the `CopyId` helper

`CopyId` currently lives inside `columns.tsx`. Extract it so the card view can reuse it.

**Files:**

- Create: `frontend/src/components/Items/CopyId.tsx`
- Modify: `frontend/src/components/Items/columns.tsx:1-32` (remove local `CopyId`, import it)

**Step 1: Create `CopyId.tsx`**

```typescript
import { Check, Copy } from "lucide-react"

import { Button } from "@/components/ui/button"
import { useCopyToClipboard } from "@/hooks/useCopyToClipboard"

export function CopyId({ id }: { id: string }) {
  const [copiedText, copy] = useCopyToClipboard()
  const isCopied = copiedText === id

  return (
    <div className="flex items-center gap-1.5 group">
      <span className="font-mono text-xs text-muted-foreground">{id}</span>
      <Button
        variant="ghost"
        size="icon"
        className="size-6 opacity-0 group-hover:opacity-100 transition-opacity"
        onClick={() => copy(id)}
      >
        {isCopied ? (
          <Check className="size-3 text-green-500" />
        ) : (
          <Copy className="size-3" />
        )}
        <span className="sr-only">Copy ID</span>
      </Button>
    </div>
  )
}
```

**Step 2: Update `columns.tsx`**

Remove the local `CopyId` function (lines 10-32) and the now-unused `Check`/`Copy`/`Button`/`useCopyToClipboard` imports. Add at the top instead:

```typescript
import { CopyId } from "./CopyId"
```

The `columns` array is unchanged — it already calls `<CopyId id={row.original.id} />`. Final imports of `columns.tsx` should be:

```typescript
import type { ColumnDef } from "@tanstack/react-table"

import type { ItemPublic } from "@/client"
import { cn } from "@/lib/utils"
import { CopyId } from "./CopyId"
import { ItemActionsMenu } from "./ItemActionsMenu"
```

**Step 3: Verify**

```bash
cd frontend && bun run lint
```

Expected: no errors, no unused-import warnings.

---

### Task 3: `ItemCard` component

**Files:**

- Create: `frontend/src/components/Items/ItemCard.tsx`

**Step 1: Implement**

```typescript
import type { ItemPublic } from "@/client"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { cn } from "@/lib/utils"
import { CopyId } from "./CopyId"
import { ItemActionsMenu } from "./ItemActionsMenu"

interface ItemCardProps {
  item: ItemPublic
}

export function ItemCard({ item }: ItemCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="truncate">{item.title}</CardTitle>
        <CardDescription
          className={cn("line-clamp-2", !item.description && "italic")}
        >
          {item.description || "No description"}
        </CardDescription>
        <CardAction>
          <ItemActionsMenu item={item} />
        </CardAction>
      </CardHeader>
      <CardContent>
        <CopyId id={item.id} />
      </CardContent>
    </Card>
  )
}
```

**Step 2: Verify**

```bash
cd frontend && bun run lint
```

Expected: no errors.

---

### Task 4: `ItemsGrid` component

**Files:**

- Create: `frontend/src/components/Items/ItemsGrid.tsx`

**Step 1: Implement**

```typescript
import type { ItemPublic } from "@/client"
import { ItemCard } from "./ItemCard"

interface ItemsGridProps {
  items: ItemPublic[]
}

export function ItemsGrid({ items }: ItemsGridProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {items.map((item) => (
        <ItemCard key={item.id} item={item} />
      ))}
    </div>
  )
}
```

**Step 2: Verify**

```bash
cd frontend && bun run lint
```

Expected: no errors.

---

### Task 5: `PendingItemsGrid` skeleton

**Files:**

- Create: `frontend/src/components/Pending/PendingItemsGrid.tsx`

**Step 1: Implement**

```typescript
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"

const PendingItemsGrid = () => (
  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
    {Array.from({ length: 6 }).map((_, index) => (
      <Card key={index}>
        <CardHeader>
          <Skeleton className="h-5 w-32" />
          <Skeleton className="h-4 w-full" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-4 w-48" />
        </CardContent>
      </Card>
    ))}
  </div>
)

export default PendingItemsGrid
```

> `key={index}` matches the existing `PendingItems.tsx` skeleton pattern (static list, never reordered).

**Step 2: Verify**

```bash
cd frontend && bun run lint
```

Expected: no errors.

---

### Task 6: Integrate toggle + card view in the route

**Files:**

- Modify: `frontend/src/routes/_layout/items.tsx` (full rewrite of the file body)

**Step 1: Replace the file contents**

```typescript
import { useSuspenseQuery } from "@tanstack/react-query"
import { createFileRoute } from "@tanstack/react-router"
import { LayoutGrid, Search, Table2 } from "lucide-react"
import { Suspense } from "react"

import { ItemsService } from "@/client"
import { DataTable } from "@/components/Common/DataTable"
import AddItem from "@/components/Items/AddItem"
import { columns } from "@/components/Items/columns"
import { ItemsGrid } from "@/components/Items/ItemsGrid"
import PendingItems from "@/components/Pending/PendingItems"
import PendingItemsGrid from "@/components/Pending/PendingItemsGrid"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useLocalStorage } from "@/hooks/useLocalStorage"

type ItemsViewMode = "table" | "cards"

function getItemsQueryOptions() {
  return {
    queryFn: () => ItemsService.readItems({ skip: 0, limit: 100 }),
    queryKey: ["items"],
  }
}

export const Route = createFileRoute("/_layout/items")({
  component: Items,
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

function ItemsContent({ view }: { view: ItemsViewMode }) {
  const { data: items } = useSuspenseQuery(getItemsQueryOptions())

  if (items.data.length === 0) {
    return <EmptyItems />
  }

  return view === "cards" ? (
    <ItemsGrid items={items.data} />
  ) : (
    <DataTable columns={columns} data={items.data} />
  )
}

function ItemsView({ view }: { view: ItemsViewMode }) {
  return (
    <Suspense
      fallback={view === "cards" ? <PendingItemsGrid /> : <PendingItems />}
    >
      <ItemsContent view={view} />
    </Suspense>
  )
}

function Items() {
  const [view, setView] = useLocalStorage<ItemsViewMode>("items-view", "table")

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Items</h1>
          <p className="text-muted-foreground">Create and manage your items</p>
        </div>
        <AddItem />
      </div>
      <div className="flex justify-end">
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
      <ItemsView view={view} />
    </div>
  )
}
```

**Notes:**
- `useLocalStorage` reads synchronously on mount (lazy `useState` initializer) — no hydration concern (Vite SPA, no SSR).
- Conditional render (not `TabsContent`) keeps the existing `Suspense` + empty-state flow intact.
- `TabsTrigger` auto-sizes lucide icons via its existing `[&_svg]` classes.

**Step 2: Verify**

```bash
cd frontend && bun run lint && bun run build
```

Expected: Biome clean; `tsc` + `vite build` succeed with no type errors.

---

### Task 7: Final verification

**Step 1: Lint + build**

```bash
cd frontend && bun run lint && bun run build
```

Expected: both pass.

**Step 2: Manual smoke check** (dev server assumed running on :5173)

- Open `/items` → table view shown by default.
- Click `Cards` → responsive card grid; each card shows title, description (or italic "No description"), copy-ID control, actions menu.
- Reload → card view restored.
- Click `Table` → table returns; reload → table restored.
- Resize viewport → 1 / 2 / 3 columns at mobile / `sm` / `lg`.

---

## Unresolved questions

None.
