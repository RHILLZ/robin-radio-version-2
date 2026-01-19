import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/providers/playback_provider.dart';
import 'package:robin_radio/services/audio_service.dart';
import 'package:robin_radio/widgets/mini_player.dart';

void main() {
  // Helper to create test track
  Track createTestTrack({
    String id = 'track-1',
    String title = 'Test Song',
    String artistName = 'Test Artist',
    String albumTitle = 'Test Album',
    String coverUrl = '',
  }) {
    return Track(
      id: id,
      title: title,
      albumId: 'album-1',
      artistName: artistName,
      albumTitle: albumTitle,
      audioUrl: 'https://example.com/audio.mp3',
      coverUrl: coverUrl,
      trackNumber: 1,
      storagePath: 'artist/album/01 Track.mp3',
    );
  }

  // Helper to create a widget with mocked playback state
  Widget createMiniPlayerWithState({
    required PlaybackState playbackState,
    VoidCallback? onTap,
  }) {
    return ProviderScope(
      overrides: [
        playbackProvider.overrideWith((ref) {
          return _MockPlaybackNotifier(playbackState);
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MiniPlayer(onTap: onTap),
        ),
      ),
    );
  }

  group('MiniPlayer', () {
    testWidgets('renders nothing when no track is playing', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: const PlaybackState(),
        ),
      );

      // SizedBox.shrink() is returned when no track
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('displays track info when playing', (tester) async {
      final track = createTestTrack(
        title: 'My Favorite Song',
        artistName: 'Awesome Artist',
      );

      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: track,
            isPlaying: true,
          ),
        ),
      );

      expect(find.text('My Favorite Song'), findsOneWidget);
      expect(find.text('Awesome Artist'), findsOneWidget);
    });

    testWidgets('shows play button when paused', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            isPlaying: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows pause button when playing', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            isPlaying: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows skip next button when hasNext is true', (tester) async {
      final queue = PlaybackQueue.fromAlbum([
        createTestTrack(id: '1'),
        createTestTrack(id: '2'),
      ], startIndex: 0);

      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            queue: queue,
            isPlaying: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('hides skip next button when hasNext is false', (tester) async {
      // Single track queue, no next
      final queue = PlaybackQueue.fromAlbum([
        createTestTrack(id: '1'),
      ], startIndex: 0);

      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            queue: queue,
            isPlaying: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.skip_next), findsNothing);
    });

    testWidgets('shows progress indicator with correct value', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            position: const Duration(seconds: 30),
            duration: const Duration(seconds: 120),
            isPlaying: true,
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      // 30/120 = 0.25
      expect(progressIndicator.value, closeTo(0.25, 0.01));
    });

    testWidgets('calls onTap when mini player is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            isPlaying: true,
          ),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(
              title: 'Song Title',
              artistName: 'Artist Name',
            ),
            isPlaying: true,
          ),
        ),
      );

      // Find the Semantics widget with the correct label
      final semantics = find.byWidgetPredicate((widget) {
        if (widget is Semantics) {
          return widget.properties.label ==
              'Now playing: Song Title by Artist Name';
        }
        return false;
      });
      expect(semantics, findsOneWidget);
    });

    testWidgets('has semantic labels for controls', (tester) async {
      final queue = PlaybackQueue.fromAlbum([
        createTestTrack(id: '1'),
        createTestTrack(id: '2'),
      ], startIndex: 0);

      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(),
            queue: queue,
            isPlaying: true,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
      expect(find.bySemanticsLabel('Skip to next track'), findsOneWidget);
    });

    testWidgets('shows album placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(
        createMiniPlayerWithState(
          playbackState: PlaybackState(
            currentTrack: createTestTrack(coverUrl: ''),
            isPlaying: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsOneWidget);
    });
  });
}

/// Mock PlaybackNotifier that provides a fixed state
class _MockPlaybackNotifier extends PlaybackNotifier {
  final PlaybackState _fixedState;

  _MockPlaybackNotifier(this._fixedState) : super(_MockAudioService());

  @override
  PlaybackState get state => _fixedState;

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> skipNext() async {}

  @override
  Future<void> skipPrevious() async {}
}

/// Minimal mock AudioService for testing
class _MockAudioService extends AudioService {
  _MockAudioService() : super();
}
