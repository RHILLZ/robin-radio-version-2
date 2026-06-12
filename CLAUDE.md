# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Robin Radio is a personal music app for a single user (Robin, on an
iPhone 15 Pro). Music albums are stored in Firebase Storage with album covers
and tracks. Core features: album browsing, fuzzy search, and a "radio" mode
that shuffles all songs. Background playback with lock-screen controls is a
hard requirement.

**Firebase Project**: `robin-radio` (bucket `robin-radio.appspot.com`).
The bucket's `Artist/{Artist Name}/{Album Title}/` folder tree IS the
database — there is no Firestore and no server. See
`specs/001-music-player/contracts/storage-schema.md` for the schema.

## Stack

Expo SDK 56 + React Native + TypeScript + Expo Router, with
react-native-track-player (audio + lock screen), Firebase JS SDK (Storage
only), zustand, fuzzball, expo-image, and expo-file-system.
See README.md for architecture, build, and distribution details
(EAS internal distribution / ad-hoc signing — no App Store).

**Expo APIs change between SDK versions** — consult the versioned docs at
https://docs.expo.dev/versions/v56.0.0/ before writing Expo-related code.

## Commands

```bash
npm test            # Jest (unit + component tests)
npm run typecheck   # tsc --noEmit
npx expo start      # Metro dev server (requires a development build, not Expo Go)
npx expo run:ios    # local iOS Simulator build (macOS only)
```

## Constitution (Non-Negotiable Principles)

See `.specify/memory/constitution.md` for full details. Key rules:

1. **Mobile-First**: Design for the phone first; test on an iPhone-sized viewport.
2. **Test-First Development**: TDD mandatory. Write failing tests before implementation.
3. **Simplicity Over Scale**: No auth, no admin UI, no analytics. Build only what Robin needs.

## Speckit Workflow

This project uses speckit for structured development. Available commands:

- `/speckit.specify` - Create feature specification from description
- `/speckit.clarify` - Ask clarification questions for spec
- `/speckit.plan` - Generate implementation plan from spec
- `/speckit.tasks` - Generate task list from plan
- `/speckit.implement` - Execute tasks from tasks.md
- `/speckit.analyze` - Cross-artifact consistency check
- `/speckit.constitution` - Update project constitution

**Workflow order**: specify → clarify → plan → tasks → implement

## Key Directories

```
src/
├── app/                      # Expo Router screens
├── components/               # UI components
├── lib/                      # catalog, player, cache, search services
├── stores/                   # zustand stores
└── types/                    # data contracts

.specify/memory/constitution.md   # Project principles (read before feature work)
specs/[feature-name]/             # Feature artifacts (spec, plan, tasks)
__mocks__/                        # Jest manual mocks for native modules
```

## Gotchas

- zustand selectors must not return fresh arrays/objects per call
  (React 19's useSyncExternalStore loops infinitely) — derive with useMemo.
- Expo Router decodes percent-encoding in route params; catalog ids contain
  encoded slashes (`%2F`), so match both forms when looking up by id.
- react-native-track-player is a native module: the app does not run in
  Expo Go, only in a development build.
