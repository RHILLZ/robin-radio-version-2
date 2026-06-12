import type { Track as PlayerTrack } from 'react-native-track-player';

import type { Track } from '../../types/catalog';
import { shuffled } from '../async';
import { sortTracksByNumber } from '../catalog/parse';

/**
 * Maps a catalog track to a react-native-track-player queue item.
 * `localUri` (when cached) becomes the playback url; `remoteUrl` is kept as a
 * custom field so the playback service can backfill the cache.
 */
export function toPlayerTrack(track: Track, localUri?: string | null): PlayerTrack {
  return {
    id: track.id,
    url: localUri ?? track.audioUrl,
    title: track.title,
    artist: track.artistName,
    album: track.albumTitle,
    artwork: track.coverUrl ?? undefined,
    duration: track.duration ?? undefined,
    remoteUrl: track.audioUrl,
  };
}

export type ResolveLocalUri = (trackId: string) => string | null;

/** Radio mode: every track in the collection, Fisher-Yates shuffled. */
export function buildShuffledQueue(
  tracks: readonly Track[],
  resolveLocalUri: ResolveLocalUri = () => null,
): PlayerTrack[] {
  return shuffled(tracks).map((t) => toPlayerTrack(t, resolveLocalUri(t.id)));
}

/** Album playback: tracks ordered by track number. */
export function buildAlbumQueue(
  tracks: readonly Track[],
  resolveLocalUri: ResolveLocalUri = () => null,
): PlayerTrack[] {
  return sortTracksByNumber([...tracks]).map((t) =>
    toPlayerTrack(t, resolveLocalUri(t.id)),
  );
}
