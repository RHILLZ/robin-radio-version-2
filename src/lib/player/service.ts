import TrackPlayer, { Event } from 'react-native-track-player';

import { cacheTrack } from '../cache/audioCache';

/**
 * Background playback service: handles lock screen / control center /
 * headphone remote events, opportunistically caches the active and next
 * track, and skips past tracks that fail to play (mirrors the Flutter
 * app's auto-skip retry behavior).
 */
export async function playbackService(): Promise<void> {
  TrackPlayer.addEventListener(Event.RemotePlay, () => TrackPlayer.play());
  TrackPlayer.addEventListener(Event.RemotePause, () => TrackPlayer.pause());
  TrackPlayer.addEventListener(Event.RemoteNext, () => TrackPlayer.skipToNext());
  TrackPlayer.addEventListener(Event.RemotePrevious, () =>
    TrackPlayer.skipToPrevious(),
  );
  TrackPlayer.addEventListener(Event.RemoteSeek, (event) =>
    TrackPlayer.seekTo(event.position),
  );

  // Performance: prefetch — cache the playing track AND the next one so
  // skips and offline replays come from disk.
  TrackPlayer.addEventListener(Event.PlaybackActiveTrackChanged, async (event) => {
    if (event.index === undefined) return;
    try {
      const queue = await TrackPlayer.getQueue();
      for (const candidate of [queue[event.index], queue[event.index + 1]]) {
        const remoteUrl = candidate?.remoteUrl as string | undefined;
        const id = candidate?.id as string | undefined;
        const url = candidate?.url as string | undefined;
        // Only cache tracks currently playing from the network.
        if (id && remoteUrl && url && !url.startsWith('file://')) {
          void cacheTrack(id, remoteUrl);
        }
      }
    } catch {
      // caching is best-effort
    }
  });

  // A broken/corrupted file must not stop the radio: skip to the next track.
  TrackPlayer.addEventListener(Event.PlaybackError, async () => {
    try {
      const [queue, activeIndex] = await Promise.all([
        TrackPlayer.getQueue(),
        TrackPlayer.getActiveTrackIndex(),
      ]);
      if (activeIndex !== undefined && activeIndex < queue.length - 1) {
        await TrackPlayer.skipToNext();
        await TrackPlayer.play();
      }
    } catch {
      // nothing else we can do
    }
  });
}
