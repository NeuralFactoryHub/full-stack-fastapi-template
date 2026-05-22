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
