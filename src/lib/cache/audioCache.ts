import type { CachedTrackInfo } from '../../types/catalog';
import {
  deleteDir,
  deleteFileIn,
  downloadFile,
  ensureDir,
  fileExists,
  fileSize,
  fileUri,
  readTextFile,
  writeTextFile,
} from '../fs';
import { selectEvictions } from './evict';

/**
 * LRU on-disk cache for audio files (same policy as the Flutter app:
 * max 20 tracks / 500MB, oldest evicted first). The index lives in memory
 * for synchronous lookups at queue-build time and is persisted as JSON.
 */
const CACHE_DIR = 'audio_cache';
const INDEX_FILE = `${CACHE_DIR}/index.json`;

let index = new Map<string, CachedTrackInfo>();
let initialized = false;
const inFlight = new Set<string>();

/** FNV-1a hash → short, filesystem-safe filename for any track id. */
export function cacheFileName(trackId: string): string {
  let hash = 0x811c9dc5;
  for (let i = 0; i < trackId.length; i++) {
    hash ^= trackId.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return `${(hash >>> 0).toString(16).padStart(8, '0')}.mp3`;
}

function persistIndex(): void {
  writeTextFile(INDEX_FILE, JSON.stringify([...index.values()]));
}

export function initAudioCache(): void {
  if (initialized) return;
  initialized = true;
  ensureDir(CACHE_DIR);
  const raw = readTextFile(INDEX_FILE);
  if (!raw) return;
  try {
    const entries = JSON.parse(raw) as CachedTrackInfo[];
    index = new Map(entries.map((e) => [e.trackId, e]));
  } catch {
    index = new Map();
  }
}

/** Local file:// URI when the track is cached and present on disk. */
export function getCachedUri(trackId: string): string | null {
  initAudioCache();
  const entry = index.get(trackId);
  if (!entry) return null;
  if (!fileExists(CACHE_DIR, cacheFileName(trackId))) {
    index.delete(trackId);
    persistIndex();
    return null;
  }
  return fileUri(CACHE_DIR, cacheFileName(trackId));
}

export function isCached(trackId: string): boolean {
  return getCachedUri(trackId) !== null;
}

/**
 * Downloads a track into the cache (no-op when already cached or already
 * downloading). Failures are silent — caching is opportunistic.
 */
export async function cacheTrack(trackId: string, remoteUrl: string): Promise<void> {
  initAudioCache();
  if (index.has(trackId) || inFlight.has(trackId)) return;
  inFlight.add(trackId);
  try {
    const name = cacheFileName(trackId);
    const uri = await downloadFile(remoteUrl, CACHE_DIR, name);
    if (!uri) return;
    index.set(trackId, {
      trackId,
      localPath: uri,
      cachedAt: Date.now(),
      fileSize: fileSize(CACHE_DIR, name),
    });
    evict();
    persistIndex();
  } finally {
    inFlight.delete(trackId);
  }
}

function evict(): void {
  for (const entry of selectEvictions([...index.values()])) {
    deleteFileIn(CACHE_DIR, cacheFileName(entry.trackId));
    index.delete(entry.trackId);
  }
}

export function getCacheStats(): { trackCount: number; totalSizeBytes: number } {
  initAudioCache();
  const entries = [...index.values()];
  return {
    trackCount: entries.length,
    totalSizeBytes: entries.reduce((sum, e) => sum + e.fileSize, 0),
  };
}

export function clearAudioCache(): void {
  deleteDir(CACHE_DIR);
  index = new Map();
  initialized = false;
}

/** Test seam. */
export function resetAudioCacheForTesting(): void {
  index = new Map();
  initialized = false;
  inFlight.clear();
}
