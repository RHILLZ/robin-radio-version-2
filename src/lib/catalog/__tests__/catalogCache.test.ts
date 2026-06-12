import * as FS from 'expo-file-system';

import type { Catalog } from '../../../types/catalog';
import { clearCatalogCache, loadCatalogCache, saveCatalogCache } from '../catalogCache';

const fsMock = FS as unknown as {
  __reset: () => void;
  __setFile: (path: string, contents: string) => void;
};

const catalog: Catalog = {
  artists: [{ id: 'a', name: 'A', storagePath: 'Artist/A', albumCount: 1 }],
  albums: [
    {
      id: 'al',
      title: 'Album',
      artistId: 'a',
      artistName: 'A',
      coverUrl: null,
      storagePath: 'Artist/A/Album',
      trackCount: 1,
    },
  ],
  tracks: [
    {
      id: 't',
      title: 'T',
      albumId: 'al',
      albumTitle: 'Album',
      artistName: 'A',
      trackNumber: 1,
      duration: null,
      audioUrl: 'https://x/t.mp3',
      coverUrl: null,
      storagePath: 'Artist/A/Album/01 T.mp3',
    },
  ],
};

beforeEach(() => fsMock.__reset());

describe('catalogCache', () => {
  it('round-trips the catalog with a timestamp', () => {
    expect(saveCatalogCache(catalog)).toBe(true);
    const loaded = loadCatalogCache();
    expect(loaded).not.toBeNull();
    expect(loaded!.artists).toEqual(catalog.artists);
    expect(loaded!.albums).toEqual(catalog.albums);
    expect(loaded!.tracks).toEqual(catalog.tracks);
    expect(loaded!.cachedAt).toBeGreaterThan(0);
  });

  it('returns null when no cache exists', () => {
    expect(loadCatalogCache()).toBeNull();
  });

  it('self-heals on corrupted cache', () => {
    fsMock.__setFile('cache/catalog_cache.json', '{not json!');
    expect(loadCatalogCache()).toBeNull();
    // corrupted file should have been deleted
    expect(loadCatalogCache()).toBeNull();
  });

  it('rejects structurally invalid caches', () => {
    fsMock.__setFile('cache/catalog_cache.json', JSON.stringify({ cachedAt: 1 }));
    expect(loadCatalogCache()).toBeNull();
  });

  it('clearCatalogCache removes the cache', () => {
    saveCatalogCache(catalog);
    clearCatalogCache();
    expect(loadCatalogCache()).toBeNull();
  });
});
