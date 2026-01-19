# Tasks: Music Player App

**Input**: Design documents from `/specs/001-music-player/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Included per Constitution requirement (Test-First Development)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/` at repository root
- **Tests**: `test/` at repository root
- **Assets**: `assets/` at repository root

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create Flutter project and configure dependencies

- [x] T001 Create Flutter project with `flutter create robin_radio --org com.robinradio --platforms ios,android`
- [x] T002 Configure pubspec.yaml with dependencies per research.md (just_audio, firebase_storage, riverpod, etc.)
- [ ] T003 [P] Configure FlutterFire with `flutterfire configure --project robin-radio` (requires interactive setup)
- [x] T004 [P] Configure iOS Info.plist for background audio mode
- [x] T005 [P] Configure Android AndroidManifest.xml with INTERNET, WAKE_LOCK, FOREGROUND_SERVICE permissions
- [x] T006 [P] Add placeholder.png asset to assets/ for missing album covers
- [x] T007 Create directory structure: lib/models/, lib/services/, lib/providers/, lib/screens/, lib/widgets/
- [x] T008 Create test directory structure: test/unit/, test/widget/, test/integration/
- [x] T009 [P] Configure analysis_options.yaml with Flutter lints

---

## Phase 2: Foundational (Core Models & Services)

**Purpose**: Create shared models and services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Models (Shared by all stories)

- [x] T010 [P] Create Artist model in lib/models/artist.dart per contracts/dart-models.md
- [x] T011 [P] Create Album model in lib/models/album.dart per contracts/dart-models.md
- [x] T012 [P] Create Track model in lib/models/track.dart per contracts/dart-models.md
- [x] T013 [P] Create PlaybackQueue model in lib/models/playback_queue.dart per contracts/dart-models.md
- [x] T014 [P] Create CachedTrack model in lib/models/cached_track.dart per contracts/dart-models.md
- [x] T015 Create models barrel export in lib/models/models.dart

### Core Services

- [x] T016 Create CatalogService interface in lib/services/catalog_service.dart (loadCatalog, getArtists, getAlbums, getTracks)
- [x] T017 Implement StorageCatalogService in lib/services/storage_catalog_service.dart (scans Firebase Storage per data-model.md)
- [x] T018 Create unit test for StorageCatalogService in test/unit/services/storage_catalog_service_test.dart
- [x] T019 Create services barrel export in lib/services/services.dart

### Core Providers

- [x] T020 Create CatalogProvider in lib/providers/catalog_provider.dart (loads and caches catalog)
- [x] T021 Create unit test for CatalogProvider in test/unit/providers/catalog_provider_test.dart

### Firebase Initialization

- [x] T022 Configure Firebase initialization in lib/main.dart with ProviderScope wrapper

**Checkpoint**: Foundation ready - all models exist, catalog loads from Firebase Storage

---

## Phase 3: User Story 1 - Play Music Instantly (Priority: P1) 🎯 MVP

**Goal**: Mom taps "Radio" button and music starts playing immediately in shuffle mode

**Independent Test**: Tap Radio button → audio plays from random track → continues to next random track

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T023 [P] [US1] Unit test for AudioService.playShuffled() in test/unit/services/audio_service_test.dart
- [x] T024 [P] [US1] Widget test for RadioButton in test/widget/widgets/radio_button_test.dart
- [x] T025 [US1] Integration test for radio playback flow in test/integration/radio_playback_test.dart

### Implementation for User Story 1

- [x] T026 [US1] Create AudioService in lib/services/audio_service.dart (play, pause, skip, previous, setQueue)
- [x] T027 [US1] Implement playShuffled(List<Track>) method that creates shuffled PlaybackQueue
- [x] T028 [US1] Create PlaybackProvider in lib/providers/playback_provider.dart (exposes current track, queue state)
- [x] T029 [US1] Create RadioButton widget in lib/widgets/radio_button.dart (prominent Radio mode trigger)
- [x] T030 [US1] Create MiniPlayer widget in lib/widgets/mini_player.dart (shows current track info)
- [x] T031 [US1] Create HomeScreen in lib/screens/home_screen.dart with RadioButton and MiniPlayer
- [x] T032 [US1] Wire HomeScreen to PlaybackProvider for state updates
- [x] T033 [US1] Add auto-advance to next shuffled track when current track completes

**Checkpoint**: Radio mode works - tap button, music plays shuffled, continues automatically

---

## Phase 4: User Story 2 - Browse and Select Albums (Priority: P2)

**Goal**: Mom sees album grid, taps album to see tracks, taps track to play

**Independent Test**: Open app → see album grid with covers → tap album → see track list → tap track → plays

### Tests for User Story 2 ⚠️

- [x] T034 [P] [US2] Widget test for AlbumGrid in test/widget/widgets/album_grid_test.dart
- [x] T035 [P] [US2] Widget test for AlbumCard in test/widget/widgets/album_card_test.dart
- [x] T036 [P] [US2] Widget test for TrackList in test/widget/widgets/track_list_test.dart
- [x] T037 [US2] Integration test for album browsing flow in test/integration/album_browsing_test.dart

### Implementation for User Story 2

- [x] T038 [P] [US2] Create AlbumCard widget in lib/widgets/album_card.dart (cover image, title, artist)
- [x] T039 [P] [US2] Create AlbumGrid widget in lib/widgets/album_grid.dart (responsive grid of AlbumCards)
- [x] T040 [US2] Integrate AlbumGrid into HomeScreen below RadioButton
- [x] T041 [US2] Create TrackListItem widget in lib/widgets/track_list_item.dart (track number, title, playing indicator)
- [x] T042 [US2] Create TrackList widget in lib/widgets/track_list.dart (scrollable list of TrackListItems)
- [x] T043 [US2] Create AlbumScreen in lib/screens/album_screen.dart (cover, track list, back navigation)
- [x] T044 [US2] Add navigation from AlbumCard tap to AlbumScreen
- [x] T045 [US2] Wire TrackListItem tap to AudioService.playFromAlbum(album, trackIndex)
- [x] T046 [US2] Implement playFromAlbum in AudioService (creates ordered PlaybackQueue starting at index)

**Checkpoint**: Album browsing works - grid displays, tap navigates, track selection plays album in order

---

## Phase 5: User Story 3 - Control Playback (Priority: P2)

**Goal**: Mom can pause, play, skip forward, skip back while music is playing

**Independent Test**: While playing → tap pause → music stops → tap play → resumes → tap skip → next track

### Tests for User Story 3 ⚠️

- [x] T047 [P] [US3] Widget test for PlayerControls in test/widget/widgets/player_controls_test.dart
- [x] T048 [P] [US3] Unit test for AudioService play/pause/skip/previous in test/unit/services/audio_service_test.dart (done in Phase 3)
- [x] T049 [US3] Integration test for playback controls in test/integration/playback_controls_test.dart

### Implementation for User Story 3

- [x] T050 [US3] Create PlayerControls widget in lib/widgets/player_controls.dart (play/pause, skip, previous buttons)
- [x] T051 [US3] Add pause(), resume(), skipNext(), skipPrevious() methods to AudioService (done in Phase 3)
- [x] T052 [US3] Update PlaybackProvider to expose isPlaying, canSkipNext, canSkipPrevious states (done in Phase 3)
- [x] T053 [US3] Create PlayerScreen in lib/screens/player_screen.dart (full-screen now playing with large controls)
- [x] T054 [US3] Update MiniPlayer to expand to PlayerScreen on tap
- [x] T055 [US3] Add seekbar/progress indicator to PlayerScreen
- [x] T056 [US3] Wire PlayerControls to AudioService via PlaybackProvider

**Checkpoint**: Playback controls work - pause/play toggles, skip advances, previous goes back

---

## Phase 6: User Story 4 - Search for Music (Priority: P3)

**Goal**: Mom types search query and finds albums/tracks with fuzzy matching

**Independent Test**: Type "Betles" → see "Beatles" results → tap result → navigates to album or plays track

### Tests for User Story 4 ✅

- [x] T057 [P] [US4] Unit test for SearchService in test/unit/services/search_service_test.dart
- [x] T058 [P] [US4] Widget test for SearchBar in test/widget/widgets/search_bar_test.dart
- [x] T059 [P] [US4] Widget test for SearchResults in test/widget/widgets/search_results_test.dart
- [x] T060 [US4] Integration test for search flow in test/integration/search_flow_test.dart

### Implementation for User Story 4 ✅

- [x] T061 [US4] Create SearchResult model in lib/models/search_result.dart per contracts/dart-models.md
- [x] T062 [US4] Create SearchService in lib/services/search_service.dart (uses fuzzywuzzy for fuzzy matching)
- [x] T063 [US4] Implement search(query) that searches artists, albums, tracks and returns ranked SearchResults
- [x] T064 [US4] Create SearchProvider in lib/providers/search_provider.dart (manages query and results state)
- [x] T065 [US4] Create SearchBar widget in lib/widgets/search_bar.dart (text input with clear button)
- [x] T066 [US4] Create SearchResultItem widget in lib/widgets/search_result_item.dart (type icon, title, subtitle)
- [x] T067 [US4] Create SearchResults widget in lib/widgets/search_results.dart (list of SearchResultItems)
- [x] T068 [US4] Create SearchScreen in lib/screens/search_screen.dart (SearchBar + SearchResults)
- [x] T069 [US4] Add search icon to HomeScreen that navigates to SearchScreen
- [x] T070 [US4] Wire SearchResultItem tap to navigate (album) or play (track)

**Checkpoint**: Search works - type query, see fuzzy results, tap to navigate/play ✅

---

## Phase 7: User Story 5 - Background and Lock Screen Playback (Priority: P2)

**Goal**: Audio continues when app is backgrounded/screen locked, lock screen controls work

**Independent Test**: Play music → lock phone → audio continues → use lock screen controls → controls work

### Tests for User Story 5 ⚠️

- [ ] T071 [US5] Integration test for background playback in test/integration/background_playback_test.dart
- [ ] T072 [US5] Manual test checklist for lock screen controls (document in test/integration/MANUAL_TESTS.md)

### Implementation for User Story 5

- [ ] T073 [US5] Configure just_audio_background in lib/services/audio_service.dart
- [ ] T074 [US5] Add AudioHandler setup for background playback notifications
- [ ] T075 [US5] Configure media notification metadata (track title, artist, album art)
- [ ] T076 [US5] Verify lock screen controls work on iOS (test on device/simulator)
- [ ] T077 [US5] Verify lock screen controls work on Android (test on device/emulator)
- [ ] T078 [US5] Handle headphone button events (play/pause toggle)

**Checkpoint**: Background playback works - audio persists, lock screen shows controls, controls functional

---

## Phase 8: Offline Caching (Cross-Cutting)

**Goal**: Cache last 10-20 played tracks for offline access

- [ ] T079 Create CacheService in lib/services/cache_service.dart (manages LRU cache of tracks)
- [ ] T080 Unit test for CacheService in test/unit/services/cache_service_test.dart
- [ ] T081 Implement cacheTrack(Track) that downloads and stores locally
- [ ] T082 Implement getCachedUrl(Track) that returns local path if cached
- [ ] T083 Implement evictOldest() when cache exceeds 20 tracks or 500MB
- [ ] T084 Create CacheProvider in lib/providers/cache_provider.dart
- [ ] T085 Integrate CacheService with AudioService (auto-cache on play)
- [ ] T086 Use LockCachingAudioSource in AudioService for transparent caching
- [ ] T087 Create OfflineIndicator widget in lib/widgets/offline_indicator.dart
- [ ] T088 Add connectivity detection to show OfflineIndicator when offline

**Checkpoint**: Offline caching works - recently played tracks available offline

---

## Phase 9: Polish & Edge Cases

**Purpose**: Handle edge cases, improve UX, final testing

- [ ] T089 [P] Add empty state widget for empty catalog in lib/widgets/empty_state.dart
- [ ] T090 [P] Add error handling for corrupted/missing audio files (skip to next)
- [ ] T091 [P] Add default placeholder for albums without cover images
- [ ] T092 [P] Add "No results found" state to SearchResults
- [ ] T093 Add loading states to HomeScreen, AlbumScreen, SearchScreen
- [ ] T094 Add pull-to-refresh on HomeScreen to reload catalog
- [ ] T095 Run flutter analyze and fix any issues
- [ ] T096 Run flutter test and ensure all tests pass
- [ ] T097 Test on physical iOS device
- [ ] T098 Test on physical Android device
- [ ] T099 Verify performance targets: album grid < 3s, audio start < 2s, search < 1s

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup → Phase 2: Foundational → [User Stories can start]
                                              ↓
                    ┌───────────────────────────────────────────────┐
                    │                                               │
                    ▼                                               ▼
              Phase 3: US1 (P1)                              Phase 7: US5 (P2)
              Radio Mode 🎯 MVP                              Background Audio
                    │                                               │
                    ▼                                               │
              Phase 4: US2 (P2)                                     │
              Album Browsing                                        │
                    │                                               │
                    ▼                                               │
              Phase 5: US3 (P2)                                     │
              Playback Controls                                     │
                    │                                               │
                    ▼                                               │
              Phase 6: US4 (P3)                                     │
              Search                                                │
                    │                                               │
                    └───────────────────────────────────────────────┘
                                              │
                                              ▼
                                      Phase 8: Offline Caching
                                              │
                                              ▼
                                      Phase 9: Polish
```

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only - **CAN BE MVP**
- **US2 (P2)**: Depends on Phase 2 only - Independent of US1
- **US3 (P2)**: Depends on US1 (AudioService exists)
- **US4 (P3)**: Depends on Phase 2 only - Independent
- **US5 (P2)**: Depends on US1 (AudioService exists)

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Models/Services before Widgets/Screens
3. Widgets before Screens
4. Core implementation before integration

### Parallel Opportunities

**Phase 1 (Setup)**:
- T003, T004, T005, T006, T009 can run in parallel

**Phase 2 (Foundational)**:
- T010, T011, T012, T013, T014 (all models) can run in parallel

**Each User Story**:
- Test tasks marked [P] can run in parallel
- Widget tasks marked [P] can run in parallel

---

## Parallel Example: User Story 2

```bash
# Launch all tests for US2 together:
Task: "Widget test for AlbumGrid in test/widget/widgets/album_grid_test.dart"
Task: "Widget test for AlbumCard in test/widget/widgets/album_card_test.dart"
Task: "Widget test for TrackList in test/widget/widgets/track_list_test.dart"

# Launch parallel widgets for US2:
Task: "Create AlbumCard widget in lib/widgets/album_card.dart"
Task: "Create AlbumGrid widget in lib/widgets/album_grid.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Radio Mode)
4. **STOP and VALIDATE**: Test Radio mode independently
5. Deploy/demo if ready - Mom can shuffle play her entire collection!

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 Radio Mode → **MVP: Mom can play music!**
3. US2 Album Browsing → Mom can browse and select albums
4. US3 Playback Controls → Full player experience
5. US4 Search → Find music quickly
6. US5 Background → Music plays when phone locked
7. Offline Caching → Works without network
8. Polish → Production ready

### Task Count Summary

| Phase | Tasks | Story |
|-------|-------|-------|
| Setup | 9 | - |
| Foundational | 13 | - |
| US1 Radio Mode | 11 | P1 |
| US2 Album Browsing | 13 | P2 |
| US3 Playback Controls | 10 | P2 |
| US4 Search | 14 | P3 |
| US5 Background | 8 | P2 |
| Offline Caching | 10 | - |
| Polish | 11 | - |
| **Total** | **99** | |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Each user story is independently testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Constitution requires TDD - tests first!
- Stop at any checkpoint to validate story independently
