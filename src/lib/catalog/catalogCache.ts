import type { Catalog } from '../../types/catalog';
import { deleteFile, readTextFile, writeTextFile } from '../fs';

const CACHE_FILE = 'catalog_cache.json';

export interface CachedCatalog extends Catalog {
  cachedAt: number;
}

/** Persists the full catalog so later launches render instantly. */
export function saveCatalogCache(catalog: Catalog): boolean {
  const payload: CachedCatalog = { ...catalog, cachedAt: Date.now() };
  return writeTextFile(CACHE_FILE, JSON.stringify(payload));
}

/** Returns the cached catalog, or null when missing/corrupted (self-heals). */
export function loadCatalogCache(): CachedCatalog | null {
  const raw = readTextFile(CACHE_FILE);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as CachedCatalog;
    if (
      !Array.isArray(parsed.artists) ||
      !Array.isArray(parsed.albums) ||
      !Array.isArray(parsed.tracks)
    ) {
      throw new Error('malformed catalog cache');
    }
    return parsed;
  } catch {
    deleteFile(CACHE_FILE);
    return null;
  }
}

export function clearCatalogCache(): void {
  deleteFile(CACHE_FILE);
}
