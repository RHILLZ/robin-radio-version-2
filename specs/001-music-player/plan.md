# Implementation Plan: Music Player App

**Branch**: `001-music-player` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-music-player/spec.md`

## Summary

Personal music streaming app for Mom (Robin) to play her digitized album collection stored in Firebase Storage. Mobile-first Flutter app for iOS/Android with Radio shuffle mode, album browsing, playback controls, fuzzy search, and offline caching of recently played content. No authentication required.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Flutter, firebase_storage, cloud_firestore, just_audio, audio_service
**Storage**: Firebase Storage (audio/images), Firestore (metadata), local cache (offline)
**Testing**: flutter_test, integration_test, mockito
**Target Platform**: iOS 15+, Android API 26+ (mobile only, no web)
**Project Type**: mobile
**Performance Goals**: Album grid < 3s load, audio start < 2s, search < 1s (per SC-001 through SC-004)
**Constraints**: Offline-capable (last 10-20 tracks), FCP < 2s on 3G, TTI < 5s (per constitution)
**Scale/Scope**: 1-3 users, hundreds of albums, single Firebase project (audilore-dev)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Mobile-First PWA ✅ PASS

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Design for mobile first | ✅ | Flutter mobile app, iOS/Android only, no web |
| Touch-first UI/UX | ✅ | Album grid, tap interactions, lock screen controls |
| Offline capability | ✅ | FR-014: Cache last 10-20 tracks offline |
| Installable | ✅ | FR-015: Native mobile app, installable on home screen |
| FCP < 2s on 3G | ⏳ | To be validated during implementation |
| TTI < 5s | ⏳ | To be validated during implementation |

### II. Test-First Development ✅ PASS

| Requirement | Status | Evidence |
|-------------|--------|----------|
| TDD workflow | ✅ | Plan includes test phases before implementation |
| Contract tests for Firebase | ✅ | Will mock Firebase Storage/Firestore in tests |
| Integration tests for audio | ✅ | Audio playback flows testable via just_audio mocks |
| Component tests for UI | ✅ | Widget tests for album grid, player controls, search |
| Coverage: search, shuffle, playback | ✅ | All core features have acceptance scenarios |

### III. Simplicity Over Scale ✅ PASS

| Requirement | Status | Evidence |
|-------------|--------|----------|
| No authentication | ✅ | Spec explicitly excludes auth |
| No admin dashboard | ✅ | Content managed via Firebase console only |
| No analytics | ✅ | Not in requirements |
| YAGNI enforced | ✅ | All features map to Robin's user stories |
| Maps to user stories | ✅ | 5 user stories, all from Robin's perspective |

**Constitution Check Result**: ✅ ALL GATES PASS

## Project Structure

### Documentation (this feature)

```text
specs/001-music-player/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Firestore schema)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── models/              # Artist, Album, Track, PlaybackQueue
├── services/            # FirebaseService, AudioService, CacheService, SearchService
├── providers/           # State management (Riverpod or similar)
├── screens/             # HomeScreen, AlbumScreen, PlayerScreen
├── widgets/             # AlbumGrid, TrackList, PlayerControls, SearchBar
└── main.dart

test/
├── unit/                # Model and service unit tests
├── widget/              # Widget component tests
└── integration/         # End-to-end flow tests

assets/
└── placeholder.png      # Default album cover
```

**Structure Decision**: Mobile app structure with lib/ for source and test/ for tests. Services layer abstracts Firebase and audio APIs for testability.

## Complexity Tracking

> No Constitution Check violations. No complexity justifications needed.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
