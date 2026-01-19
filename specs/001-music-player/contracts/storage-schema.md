# Firebase Storage Schema

**Bucket**: `gs://robin-radio.appspot.com/`

## Folder Structure

```
Artist/
└── {ArtistName}/
    └── {AlbumTitle}/
        ├── {AlbumTitle}.jpg     # Album cover image
        ├── 01 {TrackTitle}.mp3  # Audio tracks
        ├── 02 {TrackTitle}.mp3
        └── ...
```

## Naming Conventions

### Artist Folder
- Path: `Artist/{ArtistName}/`
- Name: Artist or band name as-is (may contain spaces, special chars)
- Examples: `Luther Vandross`, `Diana Ross & The Supremes`, `Kool & the Gang`

### Album Folder
- Path: `Artist/{ArtistName}/{AlbumTitle}/`
- Name: Album title as-is
- Examples: `Luther Greatest Hits`, `The Emancipation of Mimi`

### Cover Image
- Path: `Artist/{ArtistName}/{AlbumTitle}/{AlbumTitle}.jpg`
- Filename: Exact match to album folder name + `.jpg`
- Format: JPEG
- Recommended size: 500x500 to 1000x1000 pixels

### Audio Track
- Path: `Artist/{ArtistName}/{AlbumTitle}/{NN} {TrackTitle}.mp3`
- Filename pattern: `{NN} {TrackTitle}.mp3`
  - `{NN}`: Two-digit track number (01, 02, ... 14)
  - `{TrackTitle}`: Song title
- Format: MP3 (AAC/M4A also acceptable)
- Example: `01 Never Too Much.mp3`

## Parsing Rules

### Extract Track Number
```
Input:  "01 Never Too Much.mp3"
Regex:  ^(\d+)\s+(.+)\.mp3$
Result: trackNumber = 1, title = "Never Too Much"
```

### Build Storage Paths
```dart
String artistPath(String artistName) => 'Artist/$artistName/';
String albumPath(String artistName, String albumTitle) => 'Artist/$artistName/$albumTitle/';
String coverPath(String artistName, String albumTitle) => 'Artist/$artistName/$albumTitle/$albumTitle.jpg';
String trackPath(String artistName, String albumTitle, String filename) => 'Artist/$artistName/$albumTitle/$filename';
```

## Access Patterns

### List All Artists
```dart
final ref = FirebaseStorage.instance.ref('Artist/');
final result = await ref.listAll();
// result.prefixes contains artist folder references
```

### List Albums for Artist
```dart
final ref = FirebaseStorage.instance.ref('Artist/$artistName/');
final result = await ref.listAll();
// result.prefixes contains album folder references
```

### List Tracks in Album
```dart
final ref = FirebaseStorage.instance.ref('Artist/$artistName/$albumTitle/');
final result = await ref.listAll();
// result.items contains file references (.mp3 and .jpg)
```

### Get Download URL
```dart
final ref = FirebaseStorage.instance.ref(storagePath);
final url = await ref.getDownloadURL();
// Returns HTTPS URL for streaming/display
```

## Security Rules (Recommended)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /Artist/{allPaths=**} {
      // Public read access (no auth required per spec)
      allow read: if true;
      // Write access restricted to console/admin
      allow write: if false;
    }
  }
}
```
