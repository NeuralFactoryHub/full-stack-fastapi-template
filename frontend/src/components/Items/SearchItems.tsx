import { Search, X } from "lucide-react"
import { type Ref, useEffect, useRef, useState } from "react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useDebouncedCallback } from "@/hooks/useDebouncedCallback"

interface SearchItemsProps {
  value: string
  onSearch: (q: string) => void
  ref?: Ref<HTMLInputElement>
}

export function SearchItems({ value, onSearch, ref }: SearchItemsProps) {
  const [text, setText] = useState(value)
  const ownRef = useRef<HTMLInputElement>(null)
  const sent = useRef(new Set([value]))
  const { debounced, cancel } = useDebouncedCallback((q: string) => {
    sent.current.add(q)
    onSearch(q)
  }, 300)

  // Follow external URL changes (back/forward, "Clear search" in the empty
  // state); ignore the echo of what we sent ourselves so typing is not clobbered.
  useEffect(() => {
    if (sent.current.has(value)) return // echo of something we sent
    sent.current.clear()
    sent.current.add(value)
    cancel()
    setText(value)
  }, [value, cancel])

  const clear = () => {
    cancel()
    setText("")
    sent.current.add("")
    onSearch("")
    ownRef.current?.focus()
  }

  return (
    <search className="relative block w-full sm:max-w-xs">
      <Search
        aria-hidden="true"
        className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
      />
      <Input
        ref={(node) => {
          ownRef.current = node
          if (typeof ref === "function") ref(node)
          else if (ref) ref.current = node
        }}
        maxLength={255}
        value={text}
        onChange={(e) => {
          setText(e.target.value)
          debounced(e.target.value.trim())
        }}
        onKeyDown={(e) => {
          if (e.key === "Escape" && text && !e.nativeEvent.isComposing) {
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
