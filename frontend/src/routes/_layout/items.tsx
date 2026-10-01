import { useQuery, useSuspenseQuery } from "@tanstack/react-query"
import { createFileRoute } from "@tanstack/react-router"
import { LayoutGrid, Search, Table2 } from "lucide-react"
import { Suspense, useCallback, useDeferredValue, useRef } from "react"
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
  // Numbers are coerced (?q=123 parses as a number); over-long or invalid
  // values fall back to "no search" instead of hitting the API's 422.
  q: z
    .union([z.string(), z.number()])
    .transform(String)
    .transform((s) => s.trim())
    .pipe(
      z
        .string()
        .max(255)
        .refine((s) => !s.includes("\0")),
    )
    .optional()
    .catch(undefined),
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
      <h3 className="text-lg font-semibold break-all">No items match "{q}"</h3>
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

// Stable live region kept outside the aria-busy wrapper so changes are
// announced. useQuery (not suspense) reads the same cache entry as the list.
function SearchStatus({ q }: { q: string }) {
  const { data } = useQuery(getItemsQueryOptions(q))
  const count = data?.count
  let message = ""
  if (q && count !== undefined) {
    message =
      count === 0
        ? `No items match "${q}"`
        : `${count} ${count === 1 ? "item" : "items"} match "${q}"`
  }
  return <output className="sr-only">{message}</output>
}

function ItemsView(props: ItemsViewProps) {
  return (
    <Suspense
      fallback={
        props.view === "cards" ? <PendingItemsGrid /> : <PendingItems />
      }
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
  const searchRef = useRef<HTMLInputElement>(null)

  const setSearch = useCallback(
    (next: string) => {
      navigate({
        search: (prev) => ({ ...prev, q: next || undefined }),
        replace: true,
      })
    },
    [navigate],
  )
  const clearSearch = useCallback(() => {
    setSearch("")
    searchRef.current?.focus()
  }, [setSearch])

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
        <SearchItems ref={searchRef} value={q} onSearch={setSearch} />
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
        className={cn("transition-opacity", q !== deferredQ && "opacity-75")}
        aria-busy={q !== deferredQ}
      >
        <ItemsView view={view} q={deferredQ} onClearSearch={clearSearch} />
      </div>
      <SearchStatus q={deferredQ} />
    </div>
  )
}
