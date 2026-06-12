import type { Album, Artist, Track } from '../../types/catalog';

export const AUDIO_EXTENSIONS = ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'] as const;
export const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png'] as const;

const TRACK_FILENAME_RE = new RegExp(
  `^(\\d+)\\s+(.+)\\.(${AUDIO_EXTENSIONS.join('|')})$`,
  'i',
);
const AUDIO_EXT_RE = new RegExp(`\\.(${AUDIO_EXTENSIONS.join('|')})$`, 'i');
const IMAGE_EXT_RE = new RegExp(`\\.(${IMAGE_EXTENSIONS.join('|')})$`, 'i');

export function isAudioFile(filename: string): boolean {
  return AUDIO_EXT_RE.test(filename);
}

export function isImageFile(filename: string): boolean {
  return IMAGE_EXT_RE.test(filename);
}

/**
 * Parses "01 Never Too Much.mp3" → { trackNumber: 1, title: "Never Too Much" }.
 * Falls back to { trackNumber: 0, title: filename minus extension } when the
 * numbered pattern doesn't match (same fallback as the Flutter app).
 */
export function parseTrackFilename(filename: string): {
  trackNumber: number;
  title: string;
} {
  const match = TRACK_FILENAME_RE.exec(filename);
  if (match) {
    return { trackNumber: parseInt(match[1], 10), title: match[2] };
  }
  return { trackNumber: 0, title: filename.replace(AUDIO_EXT_RE, '') };
}

export function artistId(name: string): string {
  return encodeURIComponent(name);
}

export function albumId(artistName: string, albumTitle: string): string {
  return encodeURIComponent(`${artistName}/${albumTitle}`);
}

export function trackId(storagePath: string): string {
  return encodeURIComponent(storagePath);
}

export function makeArtist(name: string, storagePath: string, albumCount: number): Artist {
  return { id: artistId(name), name, storagePath, albumCount };
}

export function makeAlbum(params: {
  artistName: string;
  title: string;
  storagePath: string;
  coverUrl: string | null;
  trackCount: number;
}): Album {
  return {
    id: albumId(params.artistName, params.title),
    title: params.title,
    artistId: artistId(params.artistName),
    artistName: params.artistName,
    coverUrl: params.coverUrl,
    storagePath: params.storagePath,
    trackCount: params.trackCount,
  };
}

export function makeTrack(params: {
  filename: string;
  storagePath: string;
  artistName: string;
  albumTitle: string;
  audioUrl: string;
  coverUrl: string | null;
}): Track {
  const { trackNumber, title } = parseTrackFilename(params.filename);
  return {
    id: trackId(params.storagePath),
    title,
    albumId: albumId(params.artistName, params.albumTitle),
    albumTitle: params.albumTitle,
    artistName: params.artistName,
    trackNumber,
    duration: null,
    audioUrl: params.audioUrl,
    coverUrl: params.coverUrl,
    storagePath: params.storagePath,
  };
}

export function sortTracksByNumber(tracks: Track[]): Track[] {
  return [...tracks].sort((a, b) => a.trackNumber - b.trackNumber);
}
