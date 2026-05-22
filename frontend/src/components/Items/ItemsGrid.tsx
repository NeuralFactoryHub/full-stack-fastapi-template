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
