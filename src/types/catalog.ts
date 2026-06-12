/**
 * Core catalog entities, ported field-for-field from the Flutter app's
 * data contracts (specs/001-music-player/contracts/dart-models.md).
 *
 * IDs are URL-safe slugs derived from Firebase Storage paths so they remain
 * stable across catalog reloads and usable as router params.
 */

export interface Artist {
  /** encodeURIComponent(name) */
  id: string;
  name: string;
  /** e.g. "Artist/Luther Vandross" */
  storagePath: string;
  albumCount: number;
}

export interface Album {
  /** encodeURIComponent(`${artistName}/${title}`) */
  id: string;
  title: string;
  /** encodeURIComponent(artistName) */
  artistId: string;
  artistName: string;
  coverUrl: string | null;
  /** e.g. "Artist/Luther Vandross/Luther Greatest Hits" */
  storagePath: string;
  trackCount: number;
}

export interface Track {
  /** encodeURIComponent(storagePath) */
  id: string;
  title: string;
  albumId: string;
  albumTitle: string;
  artistName: string;
  /** Parsed from the "NN " filename prefix; 0 when unparseable. */
  trackNumber: number;
  /** Seconds; null when unknown (no ID3 read on catalog scan). */
  duration: number | null;
  audioUrl: string;
  coverUrl: string | null;
  /** e.g. "Artist/Luther Vandross/Luther Greatest Hits/01 Never Too Much.mp3" */
  storagePath: string;
}

export interface Catalog {
  artists: Artist[];
  albums: Album[];
  tracks: Track[];
}

export type SearchResultType = 'artist' | 'album' | 'track';

export interface SearchResult {
  type: SearchResultType;
  title: string;
  subtitle: string;
  coverUrl: string | null;
  /** Fuzzy match score 0-100. */
  score: number;
  artist?: Artist;
  album?: Album;
  track?: Track;
}

export interface CachedTrackInfo {
  trackId: string;
  localPath: string;
  /** Epoch ms. */
  cachedAt: number;
  fileSize: number;
}
