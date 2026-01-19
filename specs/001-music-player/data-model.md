# Data Model: Music Player App

**Branch**: `001-music-player` | **Date**: 2026-01-18

## Existing Firebase Storage Structure

**Bucket**: `gs://robin-radio.appspot.com/`
**Current Stats**: ~50 artists, ~9 albums (sample collection)

```
gs://robin-radio.appspot.com/
└── Artist/
    └── {Artist Name}/                    # e.g., "Luther Vandross"
        └── {Album Name}/                 # e.g., "Luther Greatest Hits"
            ├── {Album Name}.jpg          # Cover image (matches album folder name)
            ├── 01 {Track Title}.mp3      # Track files with number prefix
            ├── 02 {Track Title}.mp3
            └── ...
```

**Example Path**:
```
Artist/Luther Vandross/Luther Greatest Hits/
├── Luther Greatest Hits.jpg
├── 01 Never Too Much.mp3
├── 02 Don't Want To Be A Fool.mp3
├── 03 Here And Now.mp3
└── ...
```

**File Naming Convention**:
- Cover: `{Album Name}.jpg` (exact match with folder name)
- Tracks: `{NN} {Track Title}.mp3` where NN is zero-padded track number

---

## Entities

### Artist

Represents a music artist or band. Derived from Storage folder names.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | URL-safe slug from folder name |
| name | String | Yes | Artist/band name (folder name) |
| storagePath | String | Yes | Storage path: `Artist/{name}/` |
| albumCount | int | Yes | Number of albums (denormalized) |

**Validation Rules**:
- `name` derived from Storage folder name
- `id` is URL-encoded version of `name`

**Relationships**:
- One Artist → Many Albums

---

### Album

Represents a music album. Derived from Storage folder structure.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | URL-safe slug from folder path |
| title | String | Yes | Album title (folder name) |
| artistId | String | Yes | Reference to Artist |
| artistName | String | Yes | Denormalized artist name |
| coverUrl | String | Yes | Storage URL: `Artist/{artist}/{album}/{album}.jpg` |
| storagePath | String | Yes | Storage path: `Artist/{artist}/{album}/` |
| trackCount | int | Yes | Number of tracks (denormalized) |

**Validation Rules**:
- `title` derived from Storage folder name
- `coverUrl` follows pattern `{album}.jpg`

**Relationships**:
- One Album → One Artist
- One Album → Many Tracks

**Storage Path Pattern**: `Artist/{artistName}/{albumTitle}/`

---

### Track

Represents a single song. Derived from MP3 files in Storage.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | URL-safe slug from file path |
| title | String | Yes | Track title (from filename, sans number) |
| albumId | String | Yes | Reference to Album |
| albumTitle | String | Yes | Denormalized album title |
| artistName | String | Yes | Denormalized artist name |
| trackNumber | int | Yes | Position extracted from filename prefix |
| duration | int | No | Duration in seconds (from ID3 or null) |
| audioUrl | String | Yes | Firebase Storage download URL |
| coverUrl | String | Yes | Album cover URL (inherited) |
| storagePath | String | Yes | Full storage path to MP3 |

**Validation Rules**:
- `trackNumber` extracted from `{NN}` prefix in filename
- `title` extracted by removing `{NN} ` prefix and `.mp3` suffix
- `audioUrl` is Firebase Storage download URL

**Filename Pattern**: `{NN} {Track Title}.mp3`
- Example: `01 Never Too Much.mp3` → trackNumber: 1, title: "Never Too Much"

**Relationships**:
- One Track → One Album

---

### PlaybackQueue (Runtime Only)

Represents the current playback state. Not persisted.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| tracks | List<Track> | Yes | Ordered list of tracks to play |
| currentIndex | int | Yes | Current position (0-based) |
| isShuffled | bool | Yes | Whether in shuffle mode |
| originalOrder | List<Track> | No | Pre-shuffle order (for unshuffle) |

**State Transitions**:
- `idle` → `playing` (on play)
- `playing` → `paused` (on pause)
- `paused` → `playing` (on resume)
- `playing` → `idle` (on stop/clear)

---

### CachedTrack (Local Storage)

For offline playback caching.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| trackId | String | Yes | Reference to Track |
| localPath | String | Yes | Local file path |
| cachedAt | DateTime | Yes | Cache timestamp |
| fileSize | int | Yes | File size in bytes |

**Cache Rules**:
- Maximum 20 cached tracks
- LRU eviction when limit exceeded
- Total cache limit: 500MB

---

## Data Storage Strategy

### Option A: Storage-Only (No Firestore) - RECOMMENDED

Since all data exists in Storage folder structure, we can:
1. List Storage folders to get artists/albums
2. Parse filenames to extract track metadata
3. Cache the catalog locally after first load
4. No Firestore costs, simpler architecture

**Pros**:
- No Firestore setup needed
- No read/write costs
- Single source of truth (Storage)
- Aligns with "Simplicity Over Scale" principle

**Cons**:
- No duration metadata (unless we read ID3 tags)
- Slightly slower initial catalog load
- Can't add custom metadata without changing files

### Option B: Firestore Metadata Cache

Create Firestore collections mirroring Storage structure:
- One-time migration script populates from Storage
- Faster queries, can store duration/metadata
- Adds complexity and costs

**Recommendation**: Start with Option A (Storage-only). Add Firestore later only if performance requires it.

---

## Firebase Storage Bucket

**Bucket**: `robin-radio.appspot.com`
**Region**: `nam5` (US multi-region)
**Note**: Existing Firestore is in Datastore mode - may need migration to Native mode if we add metadata later.

---

## Data Loading Flow

```
App Launch
    ↓
List Artist/ folders from Storage
    ↓
For each artist, list album folders
    ↓
For each album, list files (.mp3, .jpg)
    ↓
Parse track metadata from filenames
    ↓
Cache catalog in memory + local storage
    ↓
Display album grid
```

## Migration Notes

No migration needed - the Storage structure is the source of truth. The app will:
1. Scan Storage on first launch
2. Build in-memory catalog
3. Cache locally for offline access
4. Refresh on pull-to-refresh or periodic basis
