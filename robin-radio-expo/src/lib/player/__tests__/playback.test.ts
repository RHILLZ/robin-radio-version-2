import TrackPlayer, { State } from 'react-native-track-player';

import { usePlayerStore } from '../../../stores/playerStore';
import type { Track } from '../../../types/catalog';
import {
  playAlbum,
  playShuffled,
  skipPrevious,
  stopPlayback,
  togglePlayPause,
} from '../playback';

function track(id: string, trackNumber: number): Track {
  return {
    id,
    title: `Track ${id}`,
    albumId: 'album-1',
    albumTitle: 'Album',
    artistName: 'Artist',
    trackNumber,
    duration: null,
    audioUrl: `https://example.com/${id}.mp3`,
    coverUrl: null,
    storagePath: `Artist/Artist/Album/${trackNumber} ${id}.mp3`,
  };
}

const setQueueMock = TrackPlayer.setQueue as jest.Mock;
const playMock = TrackPlayer.play as jest.Mock;
const skipMock = TrackPlayer.skip as jest.Mock;

beforeEach(() => {
  jest.clearAllMocks();
  usePlayerStore.setState({ radioActive: false });
});

describe('playShuffled', () => {
  it('queues every track, plays, and marks radio active', async () => {
    const tracks = [track('a', 1), track('b', 2), track('c', 3)];
    await playShuffled(tracks);

    expect(setQueueMock).toHaveBeenCalledTimes(1);
    const queued = setQueueMock.mock.calls[0][0];
    expect(queued).toHaveLength(3);
    expect(playMock).toHaveBeenCalled();
    expect(usePlayerStore.getState().radioActive).toBe(true);
  });

  it('does nothing with an empty collection', async () => {
    await playShuffled([]);
    expect(setQueueMock).not.toHaveBeenCalled();
    expect(usePlayerStore.getState().radioActive).toBe(false);
  });
});

describe('playAlbum', () => {
  it('queues in track order and skips to the start index', async () => {
    await playAlbum([track('c', 3), track('a', 1), track('b', 2)], 1);

    const queued = setQueueMock.mock.calls[0][0];
    expect(queued.map((q: { id: string }) => q.id)).toEqual(['a', 'b', 'c']);
    expect(skipMock).toHaveBeenCalledWith(1);
    expect(playMock).toHaveBeenCalled();
    expect(usePlayerStore.getState().radioActive).toBe(false);
  });

  it('does not skip when starting from the first track', async () => {
    await playAlbum([track('a', 1)], 0);
    expect(skipMock).not.toHaveBeenCalled();
  });
});

describe('togglePlayPause', () => {
  it('pauses while playing', async () => {
    (TrackPlayer.getPlaybackState as jest.Mock).mockResolvedValue({
      state: State.Playing,
    });
    await togglePlayPause();
    expect(TrackPlayer.pause).toHaveBeenCalled();
  });

  it('plays while paused', async () => {
    (TrackPlayer.getPlaybackState as jest.Mock).mockResolvedValue({
      state: State.Paused,
    });
    await togglePlayPause();
    expect(TrackPlayer.play).toHaveBeenCalled();
  });
});

describe('skipPrevious', () => {
  it('restarts the current track when more than 3s in', async () => {
    (TrackPlayer.getProgress as jest.Mock).mockResolvedValue({
      position: 10,
      duration: 100,
      buffered: 0,
    });
    await skipPrevious();
    expect(TrackPlayer.seekTo).toHaveBeenCalledWith(0);
    expect(TrackPlayer.skipToPrevious).not.toHaveBeenCalled();
  });

  it('goes to the previous track near the start', async () => {
    (TrackPlayer.getProgress as jest.Mock).mockResolvedValue({
      position: 1,
      duration: 100,
      buffered: 0,
    });
    await skipPrevious();
    expect(TrackPlayer.skipToPrevious).toHaveBeenCalled();
  });
});

describe('stopPlayback', () => {
  it('resets the player and turns radio off', async () => {
    usePlayerStore.setState({ radioActive: true });
    await stopPlayback();
    expect(TrackPlayer.reset).toHaveBeenCalled();
    expect(usePlayerStore.getState().radioActive).toBe(false);
  });
});
