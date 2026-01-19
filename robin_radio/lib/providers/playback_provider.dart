import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/models.dart';
import '../services/services.dart';

/// State for the playback
class PlaybackState {
  final Track? currentTrack;
  final PlaybackQueue? queue;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration? duration;
  final String? error;

  const PlaybackState({
    this.currentTrack,
    this.queue,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration,
    this.error,
  });

  bool get hasNext => queue?.hasNext ?? false;
  bool get hasPrevious => queue?.hasPrevious ?? false;
  bool get hasTrack => currentTrack != null;

  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration!.inMilliseconds;
  }

  PlaybackState copyWith({
    Track? currentTrack,
    PlaybackQueue? queue,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return PlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
    );
  }
}

/// Provider for the AudioService singleton
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Notifier for playback state management
class PlaybackNotifier extends StateNotifier<PlaybackState> {
  final AudioService _audioService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  PlaybackNotifier(this._audioService) : super(const PlaybackState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading: playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering,
      );

      // Auto-advance when track completes
      if (playerState.processingState == ProcessingState.completed) {
        _onTrackComplete();
      }
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      state = state.copyWith(duration: duration);
    });
  }

  void _onTrackComplete() {
    if (_audioService.hasNext) {
      skipNext();
    }
  }

  void _updateStateFromService() {
    state = state.copyWith(
      currentTrack: _audioService.currentTrack,
      queue: _audioService.currentQueue,
      isPlaying: _audioService.isPlaying,
    );
  }

  /// Plays all tracks in shuffled order (Radio mode)
  Future<void> playShuffled(List<Track> tracks) async {
    if (tracks.isEmpty) {
      state = state.copyWith(error: 'No tracks available');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _audioService.playShuffled(tracks);
      _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start playback: $e',
      );
    }
  }

  /// Plays tracks from an album in order
  Future<void> playFromAlbum(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      state = state.copyWith(error: 'No tracks in album');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _audioService.playFromAlbum(tracks, startIndex: startIndex);
      _updateStateFromService();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start album playback: $e',
      );
    }
  }

  /// Pauses playback
  Future<void> pause() async {
    await _audioService.pause();
  }

  /// Resumes playback
  Future<void> resume() async {
    await _audioService.resume();
  }

  /// Toggles play/pause
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Skips to the next track
  Future<void> skipNext() async {
    if (!state.hasNext) return;

    state = state.copyWith(isLoading: true);
    await _audioService.skipNext();
    _updateStateFromService();
  }

  /// Skips to the previous track
  Future<void> skipPrevious() async {
    if (!state.hasPrevious) return;

    state = state.copyWith(isLoading: true);
    await _audioService.skipPrevious();
    _updateStateFromService();
  }

  /// Seeks to a position in the current track
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  /// Seeks to a percentage of the track
  Future<void> seekToProgress(double progress) async {
    if (state.duration == null) return;
    final position = Duration(
      milliseconds: (state.duration!.inMilliseconds * progress).round(),
    );
    await seek(position);
  }

  /// Stops playback and clears the queue
  Future<void> stop() async {
    await _audioService.stop();
    state = const PlaybackState();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}

/// Main playback provider
final playbackProvider =
    StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return PlaybackNotifier(audioService);
});

/// Convenience providers
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(playbackProvider).currentTrack;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playbackProvider).isPlaying;
});

final playbackPositionProvider = Provider<Duration>((ref) {
  return ref.watch(playbackProvider).position;
});

final playbackDurationProvider = Provider<Duration?>((ref) {
  return ref.watch(playbackProvider).duration;
});

final playbackProgressProvider = Provider<double>((ref) {
  return ref.watch(playbackProvider).progress;
});
