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
