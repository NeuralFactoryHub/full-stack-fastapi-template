import { Search, X } from "lucide-react"
import { type Ref, useEffect, useLayoutEffect, useRef, useState } from "react"

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
  const valueRef = useRef(value)
  useLayoutEffect(() => {
    valueRef.current = value
  })
  // Values we pushed to the URL and have not seen echoed back yet, in order.
  const sent = useRef<string[]>([])
  // Where the URL will end up once queued sends are applied (lib has no .at()).
  const pendingTarget = () =>
    sent.current.length > 0
      ? sent.current[sent.current.length - 1]
      : valueRef.current
  const { debounced, cancel } = useDebouncedCallback((q: string) => {
    // Compare with where the URL will end up, so no stale echo gets queued.
    if (q === pendingTarget()) return
    sent.current.push(q)
    onSearch(q)
  }, 300)

  // Follow external URL changes (back/forward, sidebar link, "Clear search" in
  // the empty state); consume our own echoes so typing is not clobbered.
  useEffect(() => {
    const i = sent.current.indexOf(value)
    if (i >= 0) {
      sent.current.splice(0, i + 1)
      return
    }
    sent.current = []
    cancel()
    setText(value)
  }, [value, cancel])

  const clear = () => {
    cancel()
    setText("")
    ownRef.current?.focus()
    if (pendingTarget() !== "") {
      sent.current.push("")
      onSearch("")
    }
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
        enterKeyHint="search"
        autoComplete="off"
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
