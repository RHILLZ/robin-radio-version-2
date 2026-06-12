import * as FS from 'expo-file-system';
import TrackPlayer, { Event } from 'react-native-track-player';

import { resetAudioCacheForTesting } from '../../cache/audioCache';
import { playbackService } from '../service';

const fsMock = FS as unknown as { __reset: () => void };

type Handler = (event: Record<string, unknown>) => void | Promise<void>;

async function startServiceAndGetHandlers(): Promise<Map<string, Handler>> {
  await playbackService();
  const handlers = new Map<string, Handler>();
  for (const [event, handler] of (TrackPlayer.addEventListener as jest.Mock).mock
    .calls) {
    handlers.set(event, handler);
  }
  return handlers;
}

beforeEach(() => {
  jest.clearAllMocks();
  fsMock.__reset();
  resetAudioCacheForTesting();
});

describe('playbackService', () => {
  it('wires lock-screen remote controls', async () => {
    const handlers = await startServiceAndGetHandlers();

    await handlers.get(Event.RemotePlay)!({});
    expect(TrackPlayer.play).toHaveBeenCalled();

    await handlers.get(Event.RemotePause)!({});
    expect(TrackPlayer.pause).toHaveBeenCalled();

    await handlers.get(Event.RemoteNext)!({});
    expect(TrackPlayer.skipToNext).toHaveBeenCalled();

    await handlers.get(Event.RemoteSeek)!({ position: 42 });
    expect(TrackPlayer.seekTo).toHaveBeenCalledWith(42);
  });

  it('prefetches the active and next tracks into the audio cache', async () => {
    const handlers = await startServiceAndGetHandlers();
    (TrackPlayer.getQueue as jest.Mock).mockResolvedValue([
      { id: 't0', url: 'https://cdn/0.mp3', remoteUrl: 'https://cdn/0.mp3' },
      { id: 't1', url: 'https://cdn/1.mp3', remoteUrl: 'https://cdn/1.mp3' },
      { id: 't2', url: 'https://cdn/2.mp3', remoteUrl: 'https://cdn/2.mp3' },
    ]);

    await handlers.get(Event.PlaybackActiveTrackChanged)!({ index: 0 });
    await new Promise((r) => setTimeout(r, 0)); // let fire-and-forget caching settle

    const downloaded = (FS.File as any).downloadFileAsync.mock.calls.map(
      (call: [string]) => call[0],
    );
    expect(downloaded).toContain('https://cdn/0.mp3');
    expect(downloaded).toContain('https://cdn/1.mp3');
    expect(downloaded).not.toContain('https://cdn/2.mp3');
  });

  it('does not re-download tracks already playing from a local file', async () => {
    const handlers = await startServiceAndGetHandlers();
    (TrackPlayer.getQueue as jest.Mock).mockResolvedValue([
      { id: 't0', url: 'file:///cache/0.mp3', remoteUrl: 'https://cdn/0.mp3' },
    ]);

    await handlers.get(Event.PlaybackActiveTrackChanged)!({ index: 0 });
    await new Promise((r) => setTimeout(r, 0));

    expect((FS.File as any).downloadFileAsync).not.toHaveBeenCalled();
  });

  it('skips to the next track on playback errors', async () => {
    const handlers = await startServiceAndGetHandlers();
    (TrackPlayer.getQueue as jest.Mock).mockResolvedValue([{}, {}, {}]);
    (TrackPlayer.getActiveTrackIndex as jest.Mock).mockResolvedValue(0);

    await handlers.get(Event.PlaybackError)!({ message: 'corrupted file' });

    expect(TrackPlayer.skipToNext).toHaveBeenCalled();
    expect(TrackPlayer.play).toHaveBeenCalled();
  });

  it('stays put when the error happens on the last track', async () => {
    const handlers = await startServiceAndGetHandlers();
    (TrackPlayer.getQueue as jest.Mock).mockResolvedValue([{}, {}]);
    (TrackPlayer.getActiveTrackIndex as jest.Mock).mockResolvedValue(1);

    await handlers.get(Event.PlaybackError)!({ message: 'corrupted file' });

    expect(TrackPlayer.skipToNext).not.toHaveBeenCalled();
  });
});
