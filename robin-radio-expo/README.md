# Robin Radio (Expo)

Personal music player for a single user, rebuilt with Expo + React Native
(replacing the Flutter app in `../robin_radio`). Streams a personal music
collection from Firebase Storage with a one-tap "Radio" shuffle mode,
album browsing, fuzzy search, offline caching, and background playback with
lock-screen controls.

**Target device: iPhone (distributed outside the App Store via EAS internal
distribution / ad-hoc signing).**

## Stack

| Concern | Library |
|---|---|
| Framework | Expo SDK 56, React Native, TypeScript, Expo Router |
| Audio + lock screen | react-native-track-player v4 (native queue, remote controls) |
| Catalog backend | Firebase Storage (JS SDK) — the folder tree IS the database |
| State | zustand |
| Fuzzy search | fuzzball (JS port of fuzzywuzzy — same scoring as the Flutter app) |
| Artwork | expo-image (memory + disk cache) |
| Audio/catalog cache | expo-file-system (LRU: 20 tracks / 500 MB) |
| Connectivity | @react-native-community/netinfo |
| Tests | Jest + jest-expo + React Native Testing Library |

## Architecture

```
src/
├── app/               # Expo Router screens (home, album/[id], player, search)
├── components/        # AlbumGrid, MiniPlayer, RadioButton, skeletons, ...
├── lib/
│   ├── catalog/       # Firebase Storage scan → Artist/Album/Track + disk cache
│   ├── player/        # track-player setup, queue building, playback service
│   ├── cache/         # LRU audio file cache
│   ├── search/        # fuzzy search
│   └── fs.ts          # expo-file-system wrapper (mockable IO seam)
├── stores/            # zustand stores (catalog, player UI state)
├── hooks/             # useDebouncedValue, useIsOnline
└── types/             # data contracts (ported from the Flutter specs)
```

The music catalog is built by listing `Artist/{Artist Name}/{Album Title}/`
in the `robin-radio.appspot.com` bucket. Tracks are parsed from filenames
(`01 Never Too Much.mp3`); the cover is the image named after the album
folder. Download URLs are constructed locally (`?alt=media`) with an
automatic fallback to `getDownloadURL()` if bucket rules ever change.

## Development

```bash
npm install
npm test            # unit + component tests
npm run typecheck   # tsc --noEmit
npx expo start      # metro (requires a development build, NOT Expo Go —
                    # react-native-track-player is a native module)
```

### First-time native build (requires an Expo account + Apple Developer account)

```bash
npm install -g eas-cli
eas login
eas init                      # links the project (writes projectId to app.json)
eas update:configure          # enables OTA updates (EAS Update)
eas build --profile development --platform ios   # dev build for your own device
```

## Getting it onto Robin's iPhone (no App Store)

1. **Register her device** (one-time, remote-friendly):
   `eas device:create` → text her the link → she opens it in Safari and
   installs the profile (Settings → Profile Downloaded → Install).
2. **Build**: `eas build --profile internal --platform ios`
   (ad-hoc signing; the build only installs on registered devices).
3. **Install**: send her the build link EAS prints; she opens it in Safari
   and taps Install.
4. **Updates**: JS-only changes ship over the air with
   `eas update --channel internal` — no reinstall needed. Rebuild + resend
   the install link only for native changes or the **annual certificate
   renewal** (set a reminder: ad-hoc provisioning profiles expire after
   1 year).

## Manual device QA checklist (before handing off)

- Radio: tap Radio → lock phone → music keeps playing across track changes
- Lock screen / Control Center / Dynamic Island: play, pause, next, seek
- AirPods controls and Siri pause/resume
- Interruption: incoming call pauses, playback resumes after
- Airplane mode: cached tracks still play; offline banner appears
- Pull-to-refresh after uploading a new album to Firebase Storage

## Known follow-ups

- `eas init` / `eas update:configure` must be run once by an authenticated
  user before the first build (they write the EAS project ID into app.json).
- `assets/images/icon.png` is a 1024×1024 center-crop of the branding logo;
  regenerate if the branding changes.
