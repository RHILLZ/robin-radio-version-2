import type { Track } from '../../../types/catalog';
import { buildAlbumQueue, buildShuffledQueue, toPlayerTrack } from '../queue';

function track(id: string, trackNumber: number): Track {
  return {
    id,
    title: `Track ${id}`,
    albumId: 'album-1',
    albumTitle: 'Album',
    artistName: 'Artist',
    trackNumber,
    duration: 180,
    audioUrl: `https://example.com/${id}.mp3`,
    coverUrl: 'https://example.com/cover.jpg',
    storagePath: `Artist/Artist/Album/${trackNumber} Track.mp3`,
  };
}

describe('toPlayerTrack', () => {
  it('maps catalog fields to player fields', () => {
    const result = toPlayerTrack(track('a', 1));
    expect(result).toMatchObject({
      id: 'a',
      url: 'https://example.com/a.mp3',
      title: 'Track a',
      artist: 'Artist',
      album: 'Album',
      artwork: 'https://example.com/cover.jpg',
      duration: 180,
      remoteUrl: 'https://example.com/a.mp3',
    });
  });

  it('prefers the local uri but keeps remoteUrl for cache backfill', () => {
    const result = toPlayerTrack(track('a', 1), 'file:///cache/a.mp3');
    expect(result.url).toBe('file:///cache/a.mp3');
    expect(result.remoteUrl).toBe('https://example.com/a.mp3');
  });

  it('omits artwork when there is no cover', () => {
    const result = toPlayerTrack({ ...track('a', 1), coverUrl: null });
    expect(result.artwork).toBeUndefined();
  });
});

describe('buildShuffledQueue', () => {
  it('contains every track exactly once', () => {
    const tracks = Array.from({ length: 30 }, (_, i) => track(`t${i}`, i + 1));
    const queue = buildShuffledQueue(tracks);
    expect(queue).toHaveLength(30);
    expect(new Set(queue.map((q) => q.id)).size).toBe(30);
  });

  it('applies cached local uris', () => {
    const tracks = [track('a', 1), track('b', 2)];
    const queue = buildShuffledQueue(tracks, (id) =>
      id === 'a' ? 'file:///cache/a.mp3' : null,
    );
    const a = queue.find((q) => q.id === 'a')!;
    const b = queue.find((q) => q.id === 'b')!;
    expect(a.url).toBe('file:///cache/a.mp3');
    expect(b.url).toBe('https://example.com/b.mp3');
  });
});

describe('buildAlbumQueue', () => {
  it('orders tracks by track number', () => {
    const queue = buildAlbumQueue([track('c', 3), track('a', 1), track('b', 2)]);
    expect(queue.map((q) => q.id)).toEqual(['a', 'b', 'c']);
  });
});
