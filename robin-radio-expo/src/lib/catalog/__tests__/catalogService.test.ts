import { getDownloadURL, listAll } from 'firebase/storage';

import {
  directDownloadUrl,
  loadCatalog,
  resetUrlStrategyForTesting,
} from '../catalogService';

jest.mock('../../firebase', () => ({
  storage: {},
  STORAGE_BUCKET: 'robin-radio.appspot.com',
}));

jest.mock('firebase/storage', () => ({
  ref: jest.fn((_storage, path: string) => ({ name: path, fullPath: path })),
  listAll: jest.fn(),
  getDownloadURL: jest.fn(),
}));

interface FakeRef {
  name: string;
  fullPath: string;
}

function fakeRef(fullPath: string): FakeRef {
  const segments = fullPath.split('/');
  return { name: segments[segments.length - 1], fullPath };
}

/** fullPath → { prefixes (folders), items (files) } */
const TREE: Record<string, { prefixes: string[]; items: string[] }> = {
  Artist: {
    prefixes: ['Artist/The Beatles', 'Artist/Luther Vandross', 'Artist/Empty Artist'],
    items: [],
  },
  'Artist/The Beatles': {
    prefixes: ['Artist/The Beatles/Abbey Road'],
    items: [],
  },
  'Artist/The Beatles/Abbey Road': {
    prefixes: [],
    items: [
      'Artist/The Beatles/Abbey Road/02 Something.mp3',
      'Artist/The Beatles/Abbey Road/01 Come Together.mp3',
      'Artist/The Beatles/Abbey Road/extra.png',
      'Artist/The Beatles/Abbey Road/Abbey Road.jpg',
    ],
  },
  'Artist/Luther Vandross': {
    prefixes: ['Artist/Luther Vandross/Greatest Hits'],
    items: [],
  },
  'Artist/Luther Vandross/Greatest Hits': {
    prefixes: [],
    items: ['Artist/Luther Vandross/Greatest Hits/01 Never Too Much.mp3'],
  },
  'Artist/Empty Artist': { prefixes: [], items: [] },
};

const listAllMock = listAll as jest.Mock;
const getDownloadURLMock = getDownloadURL as jest.Mock;

beforeEach(() => {
  jest.clearAllMocks();
  resetUrlStrategyForTesting();
  listAllMock.mockImplementation(async (reference: FakeRef) => {
    const node = TREE[reference.fullPath];
    if (!node) throw new Error(`not found: ${reference.fullPath}`);
    return {
      prefixes: node.prefixes.map(fakeRef),
      items: node.items.map(fakeRef),
    };
  });
  getDownloadURLMock.mockImplementation(async (reference: FakeRef) => {
    return `https://token.example/${encodeURIComponent(reference.fullPath)}`;
  });
  global.fetch = jest.fn(async () => ({ ok: true })) as unknown as typeof fetch;
});

describe('directDownloadUrl', () => {
  it('builds a public alt=media url with the path encoded', () => {
    expect(directDownloadUrl('Artist/A B/C/01 X.mp3')).toBe(
      'https://firebasestorage.googleapis.com/v0/b/robin-radio.appspot.com/o/Artist%2FA%20B%2FC%2F01%20X.mp3?alt=media',
    );
  });
});

describe('loadCatalog', () => {
  it('builds artists, albums and ordered tracks from the storage tree', async () => {
    const catalog = await loadCatalog();

    expect(catalog.artists.map((a) => a.name).sort()).toEqual([
      'Luther Vandross',
      'The Beatles',
    ]);
    expect(catalog.albums).toHaveLength(2);
    expect(catalog.tracks).toHaveLength(3);

    const abbey = catalog.albums.find((a) => a.title === 'Abbey Road')!;
    expect(abbey.artistName).toBe('The Beatles');
    expect(abbey.trackCount).toBe(2);

    const abbeyTracks = catalog.tracks.filter((t) => t.albumId === abbey.id);
    expect(abbeyTracks.map((t) => t.trackNumber)).toEqual([1, 2]);
    expect(abbeyTracks[0].title).toBe('Come Together');
  });

  it('excludes artists with no albums', async () => {
    const catalog = await loadCatalog();
    expect(catalog.artists.some((a) => a.name === 'Empty Artist')).toBe(false);
  });

  it('prefers the cover image whose name matches the album title', async () => {
    const catalog = await loadCatalog();
    const abbey = catalog.albums.find((a) => a.title === 'Abbey Road')!;
    expect(abbey.coverUrl).toContain('Abbey%20Road.jpg');
  });

  it('uses locally constructed urls when the bucket is public (no per-file round-trips)', async () => {
    const catalog = await loadCatalog();
    expect(getDownloadURLMock).not.toHaveBeenCalled();
    expect(catalog.tracks[0].audioUrl).toContain('firebasestorage.googleapis.com');
  });

  it('falls back to getDownloadURL when direct urls are not readable', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({ ok: false });
    const catalog = await loadCatalog();
    expect(getDownloadURLMock).toHaveBeenCalled();
    expect(catalog.tracks.every((t) => t.audioUrl.startsWith('https://token.example/'))).toBe(
      true,
    );
  });

  it('emits each album progressively via onAlbum', async () => {
    const seen: string[] = [];
    await loadCatalog((discovery) => seen.push(discovery.album.title));
    expect(seen.sort()).toEqual(['Abbey Road', 'Greatest Hits']);
  });

  it('skips albums that fail to list instead of failing the whole load', async () => {
    listAllMock.mockImplementation(async (reference: FakeRef) => {
      if (reference.fullPath === 'Artist/The Beatles/Abbey Road') {
        throw new Error('storage/unknown');
      }
      const node = TREE[reference.fullPath];
      if (!node) throw new Error(`not found: ${reference.fullPath}`);
      return { prefixes: node.prefixes.map(fakeRef), items: node.items.map(fakeRef) };
    });

    const catalog = await loadCatalog();
    expect(catalog.albums.map((a) => a.title)).toEqual(['Greatest Hits']);
  });
});
