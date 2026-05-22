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
