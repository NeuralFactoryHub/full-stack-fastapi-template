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
    <search className="relative block w-full sm:max-w-xs">
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
    </search>
  )
}
