import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:just_audio/just_audio.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/services/audio_service.dart';

import 'audio_service_test.mocks.dart';

@GenerateMocks([AudioPlayer])
void main() {
  late MockAudioPlayer mockPlayer;
  late AudioService audioService;

  setUp(() {
    mockPlayer = MockAudioPlayer();
    audioService = AudioService(player: mockPlayer);

    // Default stubs
    when(mockPlayer.setAudioSource(any)).thenAnswer((_) async => null);
    when(mockPlayer.play()).thenAnswer((_) async {});
    when(mockPlayer.pause()).thenAnswer((_) async {});
    when(mockPlayer.seek(any)).thenAnswer((_) async {});
    when(mockPlayer.stop()).thenAnswer((_) async {});
    when(mockPlayer.dispose()).thenAnswer((_) async {});
    when(mockPlayer.playing).thenReturn(false);
    when(mockPlayer.playerStateStream).thenAnswer(
      (_) => Stream.value(PlayerState(false, ProcessingState.idle)),
    );
    when(mockPlayer.positionStream).thenAnswer(
      (_) => Stream.value(Duration.zero),
    );
    when(mockPlayer.durationStream).thenAnswer(
      (_) => Stream.value(Duration.zero),
    );
  });

  tearDown(() {
    audioService.dispose();
  });

  group('AudioService', () {
    final testTracks = [
      const Track(
        id: 'track1',
        title: 'Song One',
        albumId: 'album1',
        albumTitle: 'Test Album',
        artistName: 'Test Artist',
        trackNumber: 1,
        audioUrl: 'https://example.com/1.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        storagePath: 'path/1.mp3',
      ),
      const Track(
        id: 'track2',
        title: 'Song Two',
        albumId: 'album1',
        albumTitle: 'Test Album',
        artistName: 'Test Artist',
        trackNumber: 2,
        audioUrl: 'https://example.com/2.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        storagePath: 'path/2.mp3',
      ),
      const Track(
        id: 'track3',
        title: 'Song Three',
        albumId: 'album1',
        albumTitle: 'Test Album',
        artistName: 'Test Artist',
        trackNumber: 3,
        audioUrl: 'https://example.com/3.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        storagePath: 'path/3.mp3',
      ),
    ];

    group('playShuffled', () {
      test('creates shuffled queue from tracks', () async {
        await audioService.playShuffled(testTracks);

        final queue = audioService.currentQueue;
        expect(queue, isNotNull);
        expect(queue!.tracks.length, equals(3));
        expect(queue.isShuffled, isTrue);
        expect(queue.currentIndex, equals(0));
      });

      test('starts playing first track in shuffled order', () async {
        await audioService.playShuffled(testTracks);

        verify(mockPlayer.setAudioSource(any)).called(1);
        verify(mockPlayer.play()).called(1);
      });

      test('preserves original order for unshuffle', () async {
        await audioService.playShuffled(testTracks);

        final queue = audioService.currentQueue;
        expect(queue!.originalOrder, isNotNull);
        expect(queue.originalOrder!.length, equals(3));
      });

      test('handles empty track list gracefully', () async {
        await audioService.playShuffled([]);

        expect(audioService.currentQueue, isNull);
        verifyNever(mockPlayer.play());
      });

      test('handles single track', () async {
        await audioService.playShuffled([testTracks.first]);

        final queue = audioService.currentQueue;
        expect(queue, isNotNull);
        expect(queue!.tracks.length, equals(1));
      });
    });

    group('playFromAlbum', () {
      test('creates ordered queue sorted by track number', () async {
        // Pass tracks out of order
        final unorderedTracks = [testTracks[2], testTracks[0], testTracks[1]];
        await audioService.playFromAlbum(unorderedTracks, startIndex: 0);

        final queue = audioService.currentQueue;
        expect(queue, isNotNull);
        expect(queue!.isShuffled, isFalse);
        expect(queue.tracks[0].trackNumber, equals(1));
        expect(queue.tracks[1].trackNumber, equals(2));
        expect(queue.tracks[2].trackNumber, equals(3));
      });

      test('starts at specified index', () async {
        await audioService.playFromAlbum(testTracks, startIndex: 1);

        final queue = audioService.currentQueue;
        expect(queue!.currentIndex, equals(1));
      });
    });

    group('playback controls', () {
      test('pause stops playback', () async {
        await audioService.playShuffled(testTracks);
        await audioService.pause();

        verify(mockPlayer.pause()).called(1);
      });

      test('resume continues playback', () async {
        await audioService.playShuffled(testTracks);
        await audioService.pause();
        await audioService.resume();

        verify(mockPlayer.play()).called(2); // Once for playShuffled, once for resume
      });

      test('skipNext advances to next track', () async {
        await audioService.playShuffled(testTracks);
        await audioService.skipNext();

        final queue = audioService.currentQueue;
        expect(queue!.currentIndex, equals(1));
      });

      test('skipPrevious goes to previous track', () async {
        await audioService.playShuffled(testTracks);
        await audioService.skipNext(); // Go to index 1
        await audioService.skipPrevious();

        final queue = audioService.currentQueue;
        expect(queue!.currentIndex, equals(0));
      });

      test('skipNext does nothing at end of queue', () async {
        await audioService.playShuffled([testTracks.first]);
        await audioService.skipNext();

        final queue = audioService.currentQueue;
        expect(queue!.currentIndex, equals(0));
      });

      test('skipPrevious does nothing at start of queue', () async {
        await audioService.playShuffled(testTracks);
        await audioService.skipPrevious();

        final queue = audioService.currentQueue;
        expect(queue!.currentIndex, equals(0));
      });
    });

    group('currentTrack', () {
      test('returns null when no queue', () {
        expect(audioService.currentTrack, isNull);
      });

      test('returns current track from queue', () async {
        await audioService.playShuffled(testTracks);

        expect(audioService.currentTrack, isNotNull);
      });
    });

    group('hasNext and hasPrevious', () {
      test('hasNext returns true when more tracks exist', () async {
        await audioService.playShuffled(testTracks);

        expect(audioService.hasNext, isTrue);
      });

      test('hasPrevious returns false at start', () async {
        await audioService.playShuffled(testTracks);

        expect(audioService.hasPrevious, isFalse);
      });

      test('hasPrevious returns true after skip', () async {
        await audioService.playShuffled(testTracks);
        await audioService.skipNext();

        expect(audioService.hasPrevious, isTrue);
      });
    });
  });
}
