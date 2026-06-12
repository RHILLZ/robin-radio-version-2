import type { Album, Artist, Track } from '../../../types/catalog';
import { matchScore, searchCatalog } from '../searchService';

const artists: Artist[] = [
  { id: 'The%20Beatles', name: 'The Beatles', storagePath: 'Artist/The Beatles', albumCount: 2 },
  { id: 'Luther%20Vandross', name: 'Luther Vandross', storagePath: 'Artist/Luther Vandross', albumCount: 1 },
];

const albums: Album[] = [
  {
    id: 'The%20Beatles%2FAbbey%20Road',
    title: 'Abbey Road',
    artistId: 'The%20Beatles',
    artistName: 'The Beatles',
    coverUrl: 'https://example.com/abbey.jpg',
    storagePath: 'Artist/The Beatles/Abbey Road',
    trackCount: 2,
  },
];

const tracks: Track[] = [
  {
    id: 't1',
    title: 'Come Together',
    albumId: 'The%20Beatles%2FAbbey%20Road',
    albumTitle: 'Abbey Road',
    artistName: 'The Beatles',
    trackNumber: 1,
    duration: null,
    audioUrl: 'https://example.com/1.mp3',
    coverUrl: null,
    storagePath: 'Artist/The Beatles/Abbey Road/01 Come Together.mp3',
  },
  {
    id: 't2',
    title: 'Never Too Much',
    albumId: 'a2',
    albumTitle: 'Greatest Hits',
    artistName: 'Luther Vandross',
    trackNumber: 1,
    duration: null,
    audioUrl: 'https://example.com/2.mp3',
    coverUrl: null,
    storagePath: 'Artist/Luther Vandross/Greatest Hits/01 Never Too Much.mp3',
  },
];

const catalog = { artists, albums, tracks };

describe('matchScore', () => {
  it('scores exact matches 100 (case-insensitive)', () => {
    expect(matchScore('abbey road', 'Abbey Road')).toBe(100);
  });

  it('scores substring matches 95', () => {
    expect(matchScore('abbey', 'Abbey Road')).toBe(95);
  });

  it('scores misspellings above the threshold (fuzzy)', () => {
    expect(matchScore('Betles', 'The Beatles')).toBeGreaterThanOrEqual(40);
  });

  it('scores unrelated strings low', () => {
    expect(matchScore('zzzzqq', 'The Beatles')).toBeLessThan(40);
  });

  it('returns 0 for empty queries', () => {
    expect(matchScore('   ', 'anything')).toBe(0);
  });
});

describe('searchCatalog', () => {
  it('returns empty for empty query', () => {
    expect(searchCatalog(catalog, '')).toEqual([]);
    expect(searchCatalog(catalog, '   ')).toEqual([]);
  });

  it('finds artists, albums and tracks for a query', () => {
    const results = searchCatalog(catalog, 'beatles');
    const types = results.map((r) => r.type);
    expect(types).toContain('artist');
    expect(types).toContain('album');
    expect(types).toContain('track');
  });

  it('finds misspelled artists (fuzzy)', () => {
    const results = searchCatalog(catalog, 'Betles');
    expect(results.some((r) => r.type === 'artist' && r.title === 'The Beatles')).toBe(
      true,
    );
  });

  it('sorts by score descending', () => {
    const results = searchCatalog(catalog, 'never too much');
    expect(results.length).toBeGreaterThan(0);
    for (let i = 1; i < results.length; i++) {
      expect(results[i - 1].score).toBeGreaterThanOrEqual(results[i].score);
    }
    expect(results[0].title).toBe('Never Too Much');
  });

  it('caps results at maxResults', () => {
    const manyTracks = Array.from({ length: 50 }, (_, i) => ({
      ...tracks[0],
      id: `bulk-${i}`,
      title: `Come Together ${i}`,
    }));
    const results = searchCatalog({ artists: [], albums: [], tracks: manyTracks }, 'come');
    expect(results).toHaveLength(20);
  });

  it('builds the expected subtitles', () => {
    const results = searchCatalog(catalog, 'beatles');
    const artist = results.find((r) => r.type === 'artist');
    const album = results.find((r) => r.type === 'album');
    const track = results.find((r) => r.type === 'track');
    expect(artist?.subtitle).toBe('2 albums');
    expect(album?.subtitle).toBe('The Beatles');
    expect(track?.subtitle).toBe('The Beatles • Abbey Road');
  });

  it('excludes results below the minimum score', () => {
    const results = searchCatalog(catalog, 'xqzw');
    expect(results).toEqual([]);
  });
});
