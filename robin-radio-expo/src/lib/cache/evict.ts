import type { CachedTrackInfo } from '../../types/catalog';

export const MAX_CACHED_TRACKS = 20;
export const MAX_CACHE_BYTES = 500 * 1024 * 1024; // 500MB

/**
 * Pure LRU eviction: returns the entries that must be removed (oldest
 * `cachedAt` first) so the remainder satisfies both count and size limits.
 */
export function selectEvictions(
  entries: readonly CachedTrackInfo[],
  maxTracks: number = MAX_CACHED_TRACKS,
  maxBytes: number = MAX_CACHE_BYTES,
): CachedTrackInfo[] {
  const byOldest = [...entries].sort((a, b) => a.cachedAt - b.cachedAt);
  let count = byOldest.length;
  let bytes = byOldest.reduce((sum, e) => sum + e.fileSize, 0);

  const evictions: CachedTrackInfo[] = [];
  for (const entry of byOldest) {
    if (count <= maxTracks && bytes <= maxBytes) break;
    evictions.push(entry);
    count -= 1;
    bytes -= entry.fileSize;
  }
  return evictions;
}
