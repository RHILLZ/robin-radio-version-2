import { act, fireEvent, render, screen } from '@testing-library/react-native';
import NetInfo from '@react-native-community/netinfo';
import { useActiveTrack } from 'react-native-track-player';

import type { Album, Track } from '../../types/catalog';
import { AlbumCard } from '../AlbumCard';
import { OfflineIndicator } from '../OfflineIndicator';
import { RadioButton } from '../RadioButton';
import { TrackListItem } from '../TrackListItem';
import { MiniPlayer } from '../MiniPlayer';

jest.mock('expo-router', () => ({
  useRouter: () => ({ push: jest.fn(), back: jest.fn() }),
}));

const album: Album = {
  id: 'al',
  title: 'Abbey Road',
  artistId: 'a',
  artistName: 'The Beatles',
  coverUrl: 'https://example.com/cover.jpg',
  storagePath: 'Artist/The Beatles/Abbey Road',
  trackCount: 2,
};

const track: Track = {
  id: 't1',
  title: 'Come Together',
  albumId: 'al',
  albumTitle: 'Abbey Road',
  artistName: 'The Beatles',
  trackNumber: 1,
  duration: null,
  audioUrl: 'https://example.com/1.mp3',
  coverUrl: null,
  storagePath: 'Artist/The Beatles/Abbey Road/01 Come Together.mp3',
};

describe('AlbumCard', () => {
  it('renders title and artist and handles presses', async () => {
    const onPress = jest.fn();
    await render(<AlbumCard album={album} onPress={onPress} />);

    expect(screen.getByText('Abbey Road')).toBeOnTheScreen();
    expect(screen.getByText('The Beatles')).toBeOnTheScreen();

    await fireEvent.press(screen.getByLabelText('Abbey Road by The Beatles'));
    expect(onPress).toHaveBeenCalledWith(album);
  });
});

describe('TrackListItem', () => {
  it('shows the track number when not playing', async () => {
    await render(<TrackListItem track={track} isCurrent={false} onPress={jest.fn()} />);
    expect(screen.getByText('1')).toBeOnTheScreen();
    expect(screen.getByText('Come Together')).toBeOnTheScreen();
  });

  it('marks the current track as selected', async () => {
    await render(<TrackListItem track={track} isCurrent onPress={jest.fn()} />);
    expect(screen.queryByText('1')).toBeNull(); // replaced by equalizer icon
    expect(screen.getByLabelText('Play Come Together')).toBeSelected();
  });

  it('fires onPress with the track', async () => {
    const onPress = jest.fn();
    await render(<TrackListItem track={track} isCurrent={false} onPress={onPress} />);
    await fireEvent.press(screen.getByLabelText('Play Come Together'));
    expect(onPress).toHaveBeenCalledWith(track);
  });
});

describe('RadioButton', () => {
  it('handles presses when idle', async () => {
    const onPress = jest.fn();
    await render(<RadioButton active={false} onPress={onPress} />);

    await fireEvent.press(screen.getByLabelText('Turn radio on'));
    expect(onPress).toHaveBeenCalled();
  });

  it('ignores presses while loading', async () => {
    const onPress = jest.fn();
    await render(<RadioButton active loading onPress={onPress} />);
    await fireEvent.press(screen.getByLabelText('Turn radio off'));
    expect(onPress).not.toHaveBeenCalled();
  });
});

describe('OfflineIndicator', () => {
  it('is hidden while online', async () => {
    await render(<OfflineIndicator />);
    expect(screen.queryByText('Offline Mode')).toBeNull();
  });

  it('shows the banner when the connection drops', async () => {
    let listener: ((state: { isConnected: boolean }) => void) | undefined;
    (NetInfo.addEventListener as jest.Mock).mockImplementation((cb) => {
      listener = cb;
      return jest.fn();
    });

    await render(<OfflineIndicator />);
    await act(async () => listener?.({ isConnected: false }));

    expect(screen.getByText('Offline Mode')).toBeOnTheScreen();
  });
});

describe('MiniPlayer', () => {
  it('renders nothing when no track is queued', async () => {
    (useActiveTrack as jest.Mock).mockReturnValue(undefined);
    const { toJSON } = await render(<MiniPlayer />);
    expect(toJSON()).toBeNull();
  });

  it('shows the current track', async () => {
    (useActiveTrack as jest.Mock).mockReturnValue({
      id: 't1',
      title: 'Come Together',
      artist: 'The Beatles',
      artwork: 'https://example.com/cover.jpg',
    });
    await render(<MiniPlayer />);
    expect(screen.getByText('Come Together')).toBeOnTheScreen();
    expect(screen.getByText('The Beatles')).toBeOnTheScreen();
  });
});
