import type { CachedTrackInfo } from '../../../types/catalog';
import { selectEvictions } from '../evict';

function entry(id: string, cachedAt: number, fileSize = 1000): CachedTrackInfo {
  return { trackId: id, localPath: `/cache/${id}.mp3`, cachedAt, fileSize };
}

describe('selectEvictions', () => {
  it('evicts nothing under both limits', () => {
    const entries = [entry('a', 1), entry('b', 2)];
    expect(selectEvictions(entries, 20, 500_000)).toEqual([]);
  });

  it('evicts oldest entries beyond the count limit', () => {
    const entries = [entry('new', 300), entry('old', 100), entry('mid', 200)];
    const evicted = selectEvictions(entries, 2, Infinity);
    expect(evicted.map((e) => e.trackId)).toEqual(['old']);
  });

  it('evicts oldest first until under the size limit', () => {
    const entries = [
      entry('a', 1, 400),
      entry('b', 2, 400),
      entry('c', 3, 400),
    ];
    const evicted = selectEvictions(entries, 20, 800);
    expect(evicted.map((e) => e.trackId)).toEqual(['a']);
  });

  it('applies both limits together', () => {
    const entries = [
      entry('a', 1, 600),
      entry('b', 2, 600),
      entry('c', 3, 600),
      entry('d', 4, 100),
    ];
    // count limit 2 AND size limit 700 → must drop a, b
    const evicted = selectEvictions(entries, 2, 700);
    expect(evicted.map((e) => e.trackId)).toEqual(['a', 'b']);
  });

  it('handles the empty cache', () => {
    expect(selectEvictions([], 20, 500)).toEqual([]);
  });
});
