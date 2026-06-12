import { mapWithConcurrency, shuffled } from '../async';

describe('mapWithConcurrency', () => {
  it('preserves input order in results', async () => {
    const items = [30, 10, 20];
    const results = await mapWithConcurrency(items, 2, async (ms) => {
      await new Promise((r) => setTimeout(r, ms));
      return ms * 2;
    });
    expect(results).toEqual([60, 20, 40]);
  });

  it('never exceeds the concurrency limit', async () => {
    let inFlight = 0;
    let peak = 0;
    await mapWithConcurrency(Array.from({ length: 12 }, (_, i) => i), 3, async () => {
      inFlight++;
      peak = Math.max(peak, inFlight);
      await new Promise((r) => setTimeout(r, 5));
      inFlight--;
    });
    expect(peak).toBeLessThanOrEqual(3);
  });

  it('propagates rejections', async () => {
    await expect(
      mapWithConcurrency([1, 2], 2, async (n) => {
        if (n === 2) throw new Error('boom');
        return n;
      }),
    ).rejects.toThrow('boom');
  });

  it('handles empty input', async () => {
    expect(await mapWithConcurrency([], 4, async (x) => x)).toEqual([]);
  });
});

describe('shuffled', () => {
  it('is a permutation and does not mutate the input', () => {
    const input = Array.from({ length: 50 }, (_, i) => i);
    const copy = [...input];
    const result = shuffled(input);
    expect(input).toEqual(copy);
    expect([...result].sort((a, b) => a - b)).toEqual(input);
  });
});
