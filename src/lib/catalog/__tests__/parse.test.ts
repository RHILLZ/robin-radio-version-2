import {
  albumId,
  artistId,
  isAudioFile,
  isImageFile,
  makeTrack,
  parseTrackFilename,
  sortTracksByNumber,
  trackId,
} from '../parse';
import type { Track } from '../../../types/catalog';

describe('parseTrackFilename', () => {
  it('extracts track number and title from a numbered mp3', () => {
    expect(parseTrackFilename('01 Never Too Much.mp3')).toEqual({
      trackNumber: 1,
      title: 'Never Too Much',
    });
  });

  it('handles multi-digit track numbers', () => {
    expect(parseTrackFilename('12 A House Is Not a Home.mp3')).toEqual({
      trackNumber: 12,
      title: 'A House Is Not a Home',
    });
  });

  it('handles other audio extensions case-insensitively', () => {
    expect(parseTrackFilename('03 Song.M4A')).toEqual({ trackNumber: 3, title: 'Song' });
    expect(parseTrackFilename('07 Tune.flac')).toEqual({ trackNumber: 7, title: 'Tune' });
  });

  it('falls back to filename minus extension when not numbered', () => {
    expect(parseTrackFilename('Bonus Track.mp3')).toEqual({
      trackNumber: 0,
      title: 'Bonus Track',
    });
  });

  it('keeps dots inside titles', () => {
    expect(parseTrackFilename('02 Mr. Telephone Man.mp3')).toEqual({
      trackNumber: 2,
      title: 'Mr. Telephone Man',
    });
  });
});

describe('file type detection', () => {
  it.each(['a.mp3', 'b.M4A', 'c.aac', 'd.wav', 'e.flac', 'f.ogg'])(
    'recognizes audio file %s',
    (name) => expect(isAudioFile(name)).toBe(true),
  );

  it.each(['cover.jpg', 'cover.JPEG', 'cover.png'])('recognizes image %s', (name) =>
    expect(isImageFile(name)).toBe(true),
  );

  it('rejects other files', () => {
    expect(isAudioFile('notes.txt')).toBe(false);
    expect(isImageFile('track.mp3')).toBe(false);
  });
});

describe('ids', () => {
  it('builds url-safe ids matching the Flutter contracts', () => {
    expect(artistId('Luther Vandross')).toBe('Luther%20Vandross');
    expect(albumId('Luther Vandross', 'Greatest Hits')).toBe(
      'Luther%20Vandross%2FGreatest%20Hits',
    );
    expect(trackId('Artist/A/B/01 X.mp3')).toBe('Artist%2FA%2FB%2F01%20X.mp3');
  });
});

describe('makeTrack', () => {
  it('builds a complete track from a storage item', () => {
    const track = makeTrack({
      filename: '01 Never Too Much.mp3',
      storagePath: 'Artist/Luther Vandross/Greatest Hits/01 Never Too Much.mp3',
      artistName: 'Luther Vandross',
      albumTitle: 'Greatest Hits',
      audioUrl: 'https://example.com/audio.mp3',
      coverUrl: 'https://example.com/cover.jpg',
    });
    expect(track).toMatchObject({
      title: 'Never Too Much',
      trackNumber: 1,
      artistName: 'Luther Vandross',
      albumTitle: 'Greatest Hits',
      albumId: albumId('Luther Vandross', 'Greatest Hits'),
      duration: null,
    });
  });
});

describe('sortTracksByNumber', () => {
  it('sorts ascending without mutating input', () => {
    const tracks = [
      { trackNumber: 3 },
      { trackNumber: 1 },
      { trackNumber: 2 },
    ] as Track[];
    const sorted = sortTracksByNumber(tracks);
    expect(sorted.map((t) => t.trackNumber)).toEqual([1, 2, 3]);
    expect(tracks.map((t) => t.trackNumber)).toEqual([3, 1, 2]);
  });
});
