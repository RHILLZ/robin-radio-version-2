import { useEffect, useState } from 'react';

/**
 * Returns `value` after it has been stable for `delayMs`.
 * Used to debounce search input (the Flutter app searched every keystroke).
 */
export function useDebouncedValue<T>(value: T, delayMs = 250): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}
