import * as fuzz from 'fuzzball';

import type { Catalog, SearchResult } from '../../types/catalog';

/** Same thresholds as the Flutter SearchService. */
export const MIN_SCORE = 40;
export const MAX_RESULTS = 20;

/**
 * Scores `query` against `target`: exact match 100, substring 95, otherwise
 * the best of partial_ratio / token_set_ratio (fuzzball is the JS port of
 * the fuzzywuzzy library the Flutter app used, so scoring is equivalent).
 */
export function matchScore(query: string, target: string): number {
  const q = query.toLowerCase().trim();
  const t = target.toLowerCase();
  if (q.length === 0) return 0;
  if (q === t) return 100;
  if (t.includes(q)) return 95;
  return Math.max(fuzz.partial_ratio(q, t), fuzz.token_set_ratio(q, t));
}

function best(query: string, ...targets: string[]): number {
  return Math.max(...targets.map((t) => matchScore(query, t)));
}

export function searchCatalog(
  catalog: Pick<Catalog, 'artists' | 'albums' | 'tracks'>,
  query: string,
  { minScore = MIN_SCORE, maxResults = MAX_RESULTS } = {},
): SearchResult[] {
  const trimmed = query.trim();
  if (trimmed.length === 0) return [];

  const results: SearchResult[] = [];

  for (const artist of catalog.artists) {
    const score = matchScore(trimmed, artist.name);
    if (score >= minScore) {
      results.push({
        type: 'artist',
        title: artist.name,
        subtitle: `${artist.albumCount} album${artist.albumCount === 1 ? '' : 's'}`,
        coverUrl: null,
        score,
        artist,
      });
    }
  }

  for (const album of catalog.albums) {
    const score = best(trimmed, album.title, album.artistName);
    if (score >= minScore) {
      results.push({
        type: 'album',
        title: album.title,
        subtitle: album.artistName,
        coverUrl: album.coverUrl,
        score,
        album,
      });
    }
  }

  for (const track of catalog.tracks) {
    const score = best(trimmed, track.title, track.artistName, track.albumTitle);
    if (score >= minScore) {
      results.push({
        type: 'track',
        title: track.title,
        subtitle: `${track.artistName} • ${track.albumTitle}`,
        coverUrl: track.coverUrl,
        score,
        track,
      });
    }
  }

  return results.sort((a, b) => b.score - a.score).slice(0, maxResults);
}
