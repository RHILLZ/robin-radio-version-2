import { getDownloadURL, listAll, ref } from 'firebase/storage';
import type { StorageReference } from 'firebase/storage';

import type { Album, Artist, Catalog, Track } from '../../types/catalog';
import { mapWithConcurrency } from '../async';
import { storage, STORAGE_BUCKET } from '../firebase';
import {
  isAudioFile,
  isImageFile,
  makeAlbum,
  makeArtist,
  makeTrack,
  sortTracksByNumber,
} from './parse';

const ROOT_PREFIX = 'Artist';
/** Parallel Storage list/url calls. Keeps load fast without flooding the API. */
const CONCURRENCY = 6;

export interface AlbumDiscovery {
  album: Album;
  tracks: Track[];
}

/**
 * Public download URL for a Storage object, constructed locally instead of a
 * per-file getDownloadURL() round-trip. Works because the bucket is
 * public-read (the app has no auth, exactly like the Flutter version).
 */
export function directDownloadUrl(storagePath: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${STORAGE_BUCKET}/o/${encodeURIComponent(
    storagePath,
  )}?alt=media`;
}

type UrlStrategy = 'direct' | 'token';

let strategyPromise: Promise<UrlStrategy> | null = null;

/**
 * Probes whether locally-constructed URLs are readable. If Storage rules ever
 * stop allowing public reads, we fall back to getDownloadURL() (token URLs),
 * which is what the Flutter app always did.
 */
function resolveUrlStrategy(samplePath: string): Promise<UrlStrategy> {
  if (!strategyPromise) {
    strategyPromise = (async () => {
      try {
        const res = await fetch(directDownloadUrl(samplePath), { method: 'HEAD' });
        return res.ok ? 'direct' : 'token';
      } catch {
        return 'token';
      }
    })();
  }
  return strategyPromise;
}

/** Test seam. */
export function resetUrlStrategyForTesting(): void {
  strategyPromise = null;
}

async function urlFor(item: StorageReference, strategy: UrlStrategy): Promise<string> {
  if (strategy === 'direct') return directDownloadUrl(item.fullPath);
  return getDownloadURL(item);
}

/** Picks the album cover: exact "{Album}.jpg" name match first, else any image. */
function pickCoverItem(
  images: StorageReference[],
  albumTitle: string,
): StorageReference | null {
  if (images.length === 0) return null;
  const exact = images.find(
    (img) => img.name.replace(/\.(jpe?g|png)$/i, '') === albumTitle,
  );
  return exact ?? images[0];
}

async function processAlbum(
  albumPrefix: StorageReference,
  artistName: string,
): Promise<AlbumDiscovery | null> {
  const listing = await listAll(albumPrefix);
  const albumTitle = albumPrefix.name;

  const audioItems = listing.items.filter((item) => isAudioFile(item.name));
  const imageItems = listing.items.filter((item) => isImageFile(item.name));
  if (audioItems.length === 0) return null;

  const strategy = await resolveUrlStrategy(audioItems[0].fullPath);

  const coverItem = pickCoverItem(imageItems, albumTitle);
  const coverUrl = coverItem ? await urlFor(coverItem, strategy) : null;

  const tracks = await mapWithConcurrency(audioItems, CONCURRENCY, async (item) =>
    makeTrack({
      filename: item.name,
      storagePath: item.fullPath,
      artistName,
      albumTitle,
      audioUrl: await urlFor(item, strategy),
      coverUrl,
    }),
  );

  const album = makeAlbum({
    artistName,
    title: albumTitle,
    storagePath: albumPrefix.fullPath,
    coverUrl,
    trackCount: tracks.length,
  });

  return { album, tracks: sortTracksByNumber(tracks) };
}

/**
 * Scans the `Artist/{artist}/{album}/` tree and builds the full catalog.
 * Calls `onAlbum` as each album resolves so the UI can render progressively,
 * mirroring the Flutter app's streaming catalog load.
 */
export async function loadCatalog(
  onAlbum?: (discovery: AlbumDiscovery) => void,
): Promise<Catalog> {
  const rootListing = await listAll(ref(storage, ROOT_PREFIX));
  const artistPrefixes = rootListing.prefixes;

  // Stage 1: list each artist's album folders (concurrently).
  const artistAlbums = await mapWithConcurrency(
    artistPrefixes,
    CONCURRENCY,
    async (artistPrefix) => {
      const listing = await listAll(artistPrefix);
      return { artistPrefix, albumPrefixes: listing.prefixes };
    },
  );

  const artists: Artist[] = artistAlbums
    .filter(({ albumPrefixes }) => albumPrefixes.length > 0)
    .map(({ artistPrefix, albumPrefixes }) =>
      makeArtist(artistPrefix.name, artistPrefix.fullPath, albumPrefixes.length),
    );

  // Stage 2: process every album (concurrently), emitting progressively.
  const albumJobs = artistAlbums.flatMap(({ artistPrefix, albumPrefixes }) =>
    albumPrefixes.map((albumPrefix) => ({ albumPrefix, artistName: artistPrefix.name })),
  );

  const albums: Album[] = [];
  const tracks: Track[] = [];

  await mapWithConcurrency(albumJobs, CONCURRENCY, async (job) => {
    let discovery: AlbumDiscovery | null = null;
    try {
      discovery = await processAlbum(job.albumPrefix, job.artistName);
    } catch (error) {
      // A single broken album must not take the whole catalog down.
      console.warn(`Skipping album "${job.albumPrefix.fullPath}":`, error);
    }
    if (discovery) {
      albums.push(discovery.album);
      tracks.push(...discovery.tracks);
      onAlbum?.(discovery);
    }
  });

  return { artists, albums, tracks };
}
