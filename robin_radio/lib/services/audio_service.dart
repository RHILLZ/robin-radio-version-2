import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/models.dart';

/// Service for managing audio playback
class AudioService {
  final AudioPlayer _player;
  PlaybackQueue? _currentQueue;

  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  /// Current playback queue
  PlaybackQueue? get currentQueue => _currentQueue;

  /// Currently playing track
  Track? get currentTrack => _currentQueue?.currentTrack;

  /// Whether there's a next track in the queue
  bool get hasNext => _currentQueue?.hasNext ?? false;

  /// Whether there's a previous track in the queue
  bool get hasPrevious => _currentQueue?.hasPrevious ?? false;

  /// Whether the player is currently playing
  bool get isPlaying => _player.playing;

  /// Stream of player state changes
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream of playback position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of track duration
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Plays all tracks in shuffled order (Radio mode)
  Future<void> playShuffled(List<Track> tracks) async {
    if (tracks.isEmpty) {
      _currentQueue = null;
      return;
    }

    _currentQueue = PlaybackQueue.shuffled(tracks);
    await _playCurrentTrack();
  }

  /// Plays tracks from an album in order, starting at specified index
  Future<void> playFromAlbum(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      _currentQueue = null;
      return;
    }

    _currentQueue = PlaybackQueue.fromAlbum(tracks, startIndex: startIndex);
    await _playCurrentTrack();
  }

  /// Sets the queue and starts playing
  Future<void> setQueue(PlaybackQueue queue) async {
    _currentQueue = queue;
    await _playCurrentTrack();
  }

  /// Pauses playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resumes playback
  Future<void> resume() async {
    await _player.play();
  }

  /// Skips to the next track
  Future<void> skipNext() async {
    if (_currentQueue == null || !_currentQueue!.hasNext) return;

    _currentQueue = _currentQueue!.copyWith(
      currentIndex: _currentQueue!.currentIndex + 1,
    );
    await _playCurrentTrack();
  }

  /// Skips to the previous track
  Future<void> skipPrevious() async {
    if (_currentQueue == null || !_currentQueue!.hasPrevious) return;

    _currentQueue = _currentQueue!.copyWith(
      currentIndex: _currentQueue!.currentIndex - 1,
    );
    await _playCurrentTrack();
  }

  /// Seeks to a position in the current track
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Stops playback and clears the queue
  Future<void> stop() async {
    await _player.stop();
    _currentQueue = null;
  }

  /// Disposes of the audio player
  Future<void> dispose() async {
    await _player.dispose();
  }

  /// Plays the current track in the queue
  /// Throws an exception if the audio source cannot be loaded
  Future<void> _playCurrentTrack() async {
    final track = _currentQueue?.currentTrack;
    if (track == null) return;

    try {
      // Create audio source with MediaItem tag for background playback metadata
      final audioSource = AudioSource.uri(
        Uri.parse(track.audioUrl),
        tag: MediaItem(
          id: track.id,
          album: track.albumTitle,
          title: track.title,
          artist: track.artistName,
          artUri: track.coverUrl.isNotEmpty ? Uri.parse(track.coverUrl) : null,
          duration: track.duration != null
              ? Duration(seconds: track.duration!)
              : null,
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();
    } on PlayerException catch (e) {
      // Re-throw with more context for error handling upstream
      throw AudioPlaybackException(
        'Failed to play track: ${track.title}',
        cause: e,
      );
    } on PlayerInterruptedException catch (e) {
      throw AudioPlaybackException(
        'Playback interrupted for: ${track.title}',
        cause: e,
      );
    }
  }
}

/// Exception thrown when audio playback fails
class AudioPlaybackException implements Exception {
  final String message;
  final Object? cause;

  AudioPlaybackException(this.message, {this.cause});

  @override
  String toString() => 'AudioPlaybackException: $message${cause != null ? ' ($cause)' : ''}';
}
