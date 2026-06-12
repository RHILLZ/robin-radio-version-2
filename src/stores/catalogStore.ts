import { create } from 'zustand';

import {
  clearCatalogCache,
  loadCatalogCache,
  saveCatalogCache,
} from '../lib/catalog/catalogCache';
import { loadCatalog } from '../lib/catalog/catalogService';
import type { Album, Artist, Track } from '../types/catalog';

interface CatalogState {
  artists: Artist[];
  albums: Album[];
  tracks: Track[];
  isLoading: boolean;
  /** True once a full Firebase scan (or cache load) has finished. */
  isComplete: boolean;
  error: string | null;
  load: () => Promise<void>;
  refresh: () => Promise<void>;
  albumsForArtist: (artistId: string) => Album[];
  tracksForAlbum: (albumId: string) => Track[];
}

function friendlyError(error: unknown): string {
  const message = String(error);
  if (/network|fetch|timeout|connection/i.test(message)) {
    return 'No internet connection. Connect to load your music.';
  }
  if (/permission|unauthorized|403/i.test(message)) {
    return 'Permission denied. Check Firebase Storage rules.';
  }
  return 'Unable to load your music library.';
}

export const useCatalogStore = create<CatalogState>((set, get) => ({
  artists: [],
  albums: [],
  tracks: [],
  isLoading: false,
  isComplete: false,
  error: null,

  load: async () => {
    if (get().isLoading) return;
    set({ isLoading: true, error: null });

    // Disk cache first: instant render on every launch after the first.
    const cached = loadCatalogCache();
    if (cached) {
      set({
        artists: cached.artists,
        albums: cached.albums,
        tracks: cached.tracks,
        isLoading: false,
        isComplete: true,
      });
      return;
    }

    try {
      const catalog = await loadCatalog((discovery) => {
        // Progressive render: append each album as it is discovered.
        set((state) => ({
          albums: [...state.albums, discovery.album],
          tracks: [...state.tracks, ...discovery.tracks],
        }));
      });
      set({
        artists: catalog.artists,
        albums: catalog.albums,
        tracks: catalog.tracks,
        isLoading: false,
        isComplete: true,
      });
      saveCatalogCache(catalog);
    } catch (error) {
      set({ isLoading: false, error: friendlyError(error) });
    }
  },

  refresh: async () => {
    clearCatalogCache();
    set({ artists: [], albums: [], tracks: [], isComplete: false, error: null });
    await get().load();
  },

  albumsForArtist: (artistId) =>
    get().albums.filter((album) => album.artistId === artistId),

  tracksForAlbum: (albumId) =>
    get()
      .tracks.filter((track) => track.albumId === albumId)
      .sort((a, b) => a.trackNumber - b.trackNumber),
}));
