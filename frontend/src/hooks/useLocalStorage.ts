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
