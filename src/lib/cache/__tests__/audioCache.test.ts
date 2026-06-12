import * as FS from 'expo-file-system';

import {
  cacheFileName,
  cacheTrack,
  clearAudioCache,
  getCachedUri,
  getCacheStats,
  isCached,
  resetAudioCacheForTesting,
} from '../audioCache';

const fsMock = FS as unknown as {
  __reset: () => void;
  __getFile: (path: string) => string | undefined;
};

beforeEach(() => {
  fsMock.__reset();
  resetAudioCacheForTesting();
});

describe('cacheFileName', () => {
  it('produces a short stable filesystem-safe name', () => {
    const name = cacheFileName('Artist%2FX%2FY%2F01%20Some%20Track.mp3');
    expect(name).toMatch(/^[0-9a-f]{8}\.mp3$/);
    expect(cacheFileName('Artist%2FX%2FY%2F01%20Some%20Track.mp3')).toBe(name);
  });

  it('differs for different track ids', () => {
    expect(cacheFileName('a')).not.toBe(cacheFileName('b'));
  });
});

describe('audioCache', () => {
  it('returns null for uncached tracks', () => {
    expect(getCachedUri('unknown')).toBeNull();
    expect(isCached('unknown')).toBe(false);
  });

  it('caches a track and returns its local uri', async () => {
    await cacheTrack('track-1', 'https://example.com/audio.mp3');
    const uri = getCachedUri('track-1');
    expect(uri).toMatch(/^file:\/\/\/cache\/audio_cache\/[0-9a-f]{8}\.mp3$/);
    expect(isCached('track-1')).toBe(true);
  });

  it('does not re-download already cached tracks', async () => {
    await cacheTrack('track-1', 'https://example.com/audio.mp3');
    await cacheTrack('track-1', 'https://example.com/audio.mp3');
    expect((FS.File as any).downloadFileAsync).toHaveBeenCalledTimes(1);
  });

  it('persists the index across re-initialization', async () => {
    await cacheTrack('track-1', 'https://example.com/audio.mp3');
    resetAudioCacheForTesting(); // simulates app restart (files stay on disk)
    expect(isCached('track-1')).toBe(true);
  });

  it('self-heals when the cached file disappeared', async () => {
    await cacheTrack('track-1', 'https://example.com/audio.mp3');
    const fileName = cacheFileName('track-1');
    new FS.File(FS.Paths.cache, 'audio_cache', fileName).delete();
    expect(getCachedUri('track-1')).toBeNull();
  });

  it('reports cache stats', async () => {
    await cacheTrack('track-1', 'https://example.com/a.mp3');
    await cacheTrack('track-2', 'https://example.com/b.mp3');
    const stats = getCacheStats();
    expect(stats.trackCount).toBe(2);
    expect(stats.totalSizeBytes).toBeGreaterThan(0);
  });

  it('clearAudioCache empties everything', async () => {
    await cacheTrack('track-1', 'https://example.com/a.mp3');
    clearAudioCache();
    expect(isCached('track-1')).toBe(false);
    expect(getCacheStats().trackCount).toBe(0);
  });

  it('evicts the oldest tracks beyond the count limit', async () => {
    jest.useFakeTimers();
    try {
      for (let i = 0; i < 22; i++) {
        jest.setSystemTime(1_000_000 + i * 1000);
        await cacheTrack(`track-${i}`, `https://example.com/${i}.mp3`);
      }
      expect(getCacheStats().trackCount).toBe(20);
      expect(isCached('track-0')).toBe(false);
      expect(isCached('track-1')).toBe(false);
      expect(isCached('track-21')).toBe(true);
    } finally {
      jest.useRealTimers();
    }
  });
});
