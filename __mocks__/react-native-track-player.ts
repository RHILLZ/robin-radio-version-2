/**
 * Manual Jest mock for react-native-track-player (native module).
 * Enum values mirror the real v4 string constants used by app code.
 */

export const State = {
  None: 'none',
  Ready: 'ready',
  Playing: 'playing',
  Paused: 'paused',
  Stopped: 'stopped',
  Ended: 'ended',
  Buffering: 'buffering',
  Loading: 'loading',
  Error: 'error',
} as const;

export const Event = {
  RemotePlay: 'remote-play',
  RemotePause: 'remote-pause',
  RemoteNext: 'remote-next',
  RemotePrevious: 'remote-previous',
  RemoteSeek: 'remote-seek',
  RemoteStop: 'remote-stop',
  PlaybackState: 'playback-state',
  PlaybackError: 'playback-error',
  PlaybackQueueEnded: 'playback-queue-ended',
  PlaybackActiveTrackChanged: 'playback-active-track-changed',
} as const;

export const Capability = {
  Play: 'play',
  Pause: 'pause',
  Stop: 'stop',
  SeekTo: 'seek-to',
  SkipToNext: 'skip-to-next',
  SkipToPrevious: 'skip-to-previous',
} as const;

export const AppKilledPlaybackBehavior = {
  ContinuePlayback: 'continue-playback',
  PausePlayback: 'pause-playback',
  StopPlaybackAndRemoveNotification: 'stop-playback-and-remove-notification',
} as const;

export const RepeatMode = { Off: 0, Track: 1, Queue: 2 } as const;

export const useActiveTrack = jest.fn(() => undefined);
export const usePlaybackState = jest.fn(() => ({ state: undefined }));
export const useProgress = jest.fn(() => ({ position: 0, duration: 0, buffered: 0 }));
export const useTrackPlayerEvents = jest.fn();

const TrackPlayer = {
  setupPlayer: jest.fn(async () => {}),
  updateOptions: jest.fn(async () => {}),
  registerPlaybackService: jest.fn(),
  setQueue: jest.fn(async () => {}),
  add: jest.fn(async () => {}),
  load: jest.fn(async () => {}),
  play: jest.fn(async () => {}),
  pause: jest.fn(async () => {}),
  stop: jest.fn(async () => {}),
  reset: jest.fn(async () => {}),
  skip: jest.fn(async () => {}),
  skipToNext: jest.fn(async () => {}),
  skipToPrevious: jest.fn(async () => {}),
  seekTo: jest.fn(async () => {}),
  getProgress: jest.fn(async () => ({ position: 0, duration: 0, buffered: 0 })),
  getPlaybackState: jest.fn(async () => ({ state: State.None })),
  getQueue: jest.fn(async () => []),
  getActiveTrackIndex: jest.fn(async () => undefined),
  getActiveTrack: jest.fn(async () => undefined),
  addEventListener: jest.fn(() => ({ remove: jest.fn() })),
};

export default TrackPlayer;
