import * as FS from 'expo-file-system';

import { loadCatalog } from '../../lib/catalog/catalogService';
import type { Catalog } from '../../types/catalog';
import { useCatalogStore } from '../catalogStore';

jest.mock('../../lib/catalog/catalogService', () => ({
  loadCatalog: jest.fn(),
}));

const loadCatalogMock = loadCatalog as jest.Mock;
const fsMock = FS as unknown as { __reset: () => void };

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
      trackCount: 2,
    },
  ],
  tracks: [
    {
      id: 't2',
      title: 'Two',
      albumId: 'al',
      albumTitle: 'Album',
      artistName: 'A',
      trackNumber: 2,
      duration: null,
      audioUrl: 'https://x/2.mp3',
      coverUrl: null,
      storagePath: 'Artist/A/Album/02 Two.mp3',
    },
    {
      id: 't1',
      title: 'One',
      albumId: 'al',
      albumTitle: 'Album',
      artistName: 'A',
      trackNumber: 1,
      duration: null,
      audioUrl: 'https://x/1.mp3',
      coverUrl: null,
      storagePath: 'Artist/A/Album/01 One.mp3',
    },
  ],
};

beforeEach(() => {
  jest.clearAllMocks();
  fsMock.__reset();
  useCatalogStore.setState({
    artists: [],
    albums: [],
    tracks: [],
    isLoading: false,
    isComplete: false,
    error: null,
  });
});

describe('catalogStore.load', () => {
  it('loads from Firebase and persists to the disk cache', async () => {
    loadCatalogMock.mockResolvedValue(catalog);

    await useCatalogStore.getState().load();

    const state = useCatalogStore.getState();
    expect(state.albums).toHaveLength(1);
    expect(state.tracks).toHaveLength(2);
    expect(state.isComplete).toBe(true);
    expect(state.error).toBeNull();

    // Second load must come from the disk cache, not Firebase.
    useCatalogStore.setState({ artists: [], albums: [], tracks: [], isComplete: false });
    await useCatalogStore.getState().load();
    expect(loadCatalogMock).toHaveBeenCalledTimes(1);
    expect(useCatalogStore.getState().albums).toHaveLength(1);
  });

  it('exposes progressive album discoveries while loading', async () => {
    loadCatalogMock.mockImplementation(async (onAlbum) => {
      onAlbum?.({ album: catalog.albums[0], tracks: catalog.tracks });
      return catalog;
    });

    await useCatalogStore.getState().load();
    expect(useCatalogStore.getState().albums).toHaveLength(1);
  });

  it('maps network failures to a friendly error', async () => {
    loadCatalogMock.mockRejectedValue(new Error('network request failed'));

    await useCatalogStore.getState().load();

    const state = useCatalogStore.getState();
    expect(state.error).toMatch(/No internet connection/);
    expect(state.isLoading).toBe(false);
  });

  it('refresh clears the cache and reloads from Firebase', async () => {
    loadCatalogMock.mockResolvedValue(catalog);
    await useCatalogStore.getState().load();

    await useCatalogStore.getState().refresh();
    expect(loadCatalogMock).toHaveBeenCalledTimes(2);
  });
});

describe('catalog selectors', () => {
  it('tracksForAlbum returns tracks sorted by number', async () => {
    loadCatalogMock.mockResolvedValue(catalog);
    await useCatalogStore.getState().load();

    const tracks = useCatalogStore.getState().tracksForAlbum('al');
    expect(tracks.map((t) => t.trackNumber)).toEqual([1, 2]);
  });

  it('albumsForArtist filters by artist id', async () => {
    loadCatalogMock.mockResolvedValue(catalog);
    await useCatalogStore.getState().load();

    expect(useCatalogStore.getState().albumsForArtist('a')).toHaveLength(1);
    expect(useCatalogStore.getState().albumsForArtist('other')).toHaveLength(0);
  });
});
