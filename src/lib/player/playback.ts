import TrackPlayer, { State } from 'react-native-track-player';

import type { Track } from '../../types/catalog';
import { getCachedUri } from '../cache/audioCache';
import { usePlayerStore } from '../../stores/playerStore';
import { buildAlbumQueue, buildShuffledQueue } from './queue';
import { ensurePlayerSetup } from './setup';

/** Radio mode: shuffle the entire collection and play. */
export async function playShuffled(allTracks: readonly Track[]): Promise<void> {
  if (allTracks.length === 0) return;
  await ensurePlayerSetup();
  const queue = buildShuffledQueue(allTracks, getCachedUri);
  await TrackPlayer.setQueue(queue);
  await TrackPlayer.play();
  usePlayerStore.getState().setRadioActive(true);
}

/** Plays an album in track order, starting at `startIndex`. */
export async function playAlbum(
  albumTracks: readonly Track[],
  startIndex = 0,
): Promise<void> {
  if (albumTracks.length === 0) return;
  await ensurePlayerSetup();
  const queue = buildAlbumQueue(albumTracks, getCachedUri);
  await TrackPlayer.setQueue(queue);
  if (startIndex > 0 && startIndex < queue.length) {
    await TrackPlayer.skip(startIndex);
  }
  await TrackPlayer.play();
  usePlayerStore.getState().setRadioActive(false);
}

/** Plays a single track (used from search results). */
export async function playTrack(track: Track): Promise<void> {
  return playAlbum([track], 0);
}

export async function togglePlayPause(): Promise<void> {
  const { state } = await TrackPlayer.getPlaybackState();
  if (state === State.Playing) {
    await TrackPlayer.pause();
  } else {
    await TrackPlayer.play();
  }
}

export async function skipNext(): Promise<void> {
  try {
    await TrackPlayer.skipToNext();
  } catch {
    // already at end of queue
  }
}

/**
 * Previous: restarts the current track when more than 3s in (the behavior
 * spec'd in user story 3), otherwise goes to the previous track.
 */
export async function skipPrevious(): Promise<void> {
  const { position } = await TrackPlayer.getProgress();
  if (position > 3) {
    await TrackPlayer.seekTo(0);
    return;
  }
  try {
    await TrackPlayer.skipToPrevious();
  } catch {
    await TrackPlayer.seekTo(0);
  }
}

export async function seekToProgress(progress: number): Promise<void> {
  const { duration } = await TrackPlayer.getProgress();
  if (duration > 0) {
    await TrackPlayer.seekTo(Math.max(0, Math.min(1, progress)) * duration);
  }
}

/** Stops playback and clears the queue (radio toggle off). */
export async function stopPlayback(): Promise<void> {
  await TrackPlayer.reset();
  usePlayerStore.getState().setRadioActive(false);
}
