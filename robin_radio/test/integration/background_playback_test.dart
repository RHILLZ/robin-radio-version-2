import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:just_audio/just_audio.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/services/audio_service.dart';

import '../unit/services/audio_service_test.mocks.dart';

/// Integration tests for background playback functionality
///
/// Note: Actual background playback requires a real device or emulator.
/// These tests verify the AudioService is configured correctly for background
/// audio and that the necessary handlers are set up.
void main() {
  late MockAudioPlayer mockPlayer;
  late AudioService audioService;

  const testTrack = Track(
    id: 'track-1',
    title: 'Test Song',
    albumId: 'album-1',
    albumTitle: 'Test Album',
    artistName: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg',
    audioUrl: 'https://example.com/song.mp3',
    storagePath: 'Artists/Test Artist/Test Album/01 Test Song.mp3',
    trackNumber: 1,
    duration: 210,
  );

  setUp(() {
    mockPlayer = MockAudioPlayer();

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
      (_) => Stream.value(const Duration(seconds: 210)),
    );

    audioService = AudioService(player: mockPlayer);
  });

  tearDown(() {
    audioService.dispose();
  });

  group('Background Playback Configuration', () {
    test('AudioService can be initialized', () {
      expect(audioService, isNotNull);
    });

    test('AudioService exposes player state stream', () {
      expect(audioService.playerStateStream, isNotNull);
    });

    test('AudioService exposes position stream', () {
      expect(audioService.positionStream, isNotNull);
    });

    test('AudioService exposes duration stream', () {
      expect(audioService.durationStream, isNotNull);
    });

    test('playback continues after setting audio source', () async {
      await audioService.playFromAlbum([testTrack], startIndex: 0);

      verify(mockPlayer.setAudioSource(any)).called(1);
      verify(mockPlayer.play()).called(1);
    });

    test('pause stops playback without disposing', () async {
      await audioService.playFromAlbum([testTrack], startIndex: 0);
      await audioService.pause();

      verify(mockPlayer.pause()).called(1);
      verifyNever(mockPlayer.dispose());
    });

    test('resume continues playback', () async {
      await audioService.playFromAlbum([testTrack], startIndex: 0);
      await audioService.pause();
      await audioService.resume();

      verify(mockPlayer.play()).called(2); // Once for initial play, once for resume
    });

    test('current track info is available', () async {
      await audioService.playFromAlbum([testTrack], startIndex: 0);

      final track = audioService.currentTrack;
      expect(track, isNotNull);
      expect(track!.title, equals('Test Song'));
      expect(track.artistName, equals('Test Artist'));
      expect(track.albumTitle, equals('Test Album'));
    });
  });

  group('Media Controls Simulation', () {
    test('skip next advances to next track', () async {
      final tracks = [
        testTrack,
        testTrack.copyWith(id: 'track-2', title: 'Song Two'),
      ];

      await audioService.playFromAlbum(tracks, startIndex: 0);
      await audioService.skipNext();

      expect(audioService.currentTrack?.title, equals('Song Two'));
    });

    test('skip previous goes back to previous track', () async {
      final tracks = [
        testTrack,
        testTrack.copyWith(id: 'track-2', title: 'Song Two'),
      ];

      await audioService.playFromAlbum(tracks, startIndex: 1);
      await audioService.skipPrevious();

      expect(audioService.currentTrack?.title, equals('Test Song'));
    });

    test('seek changes playback position', () async {
      await audioService.playFromAlbum([testTrack], startIndex: 0);

      const seekPosition = Duration(seconds: 30);
      await audioService.seek(seekPosition);

      verify(mockPlayer.seek(seekPosition)).called(1);
    });
  });
}
