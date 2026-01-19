import 'track.dart';

class PlaybackQueue {
  final List<Track> tracks;
  final int currentIndex;
  final bool isShuffled;
  final List<Track>? originalOrder;

  const PlaybackQueue({
    required this.tracks,
    required this.currentIndex,
    required this.isShuffled,
    this.originalOrder,
  });

  Track? get currentTrack =>
      tracks.isNotEmpty && currentIndex >= 0 && currentIndex < tracks.length
          ? tracks[currentIndex]
          : null;

  bool get hasNext => currentIndex < tracks.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlaybackQueue copyWith({
    List<Track>? tracks,
    int? currentIndex,
    bool? isShuffled,
    List<Track>? originalOrder,
  }) {
    return PlaybackQueue(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      originalOrder: originalOrder ?? this.originalOrder,
    );
  }

  /// Creates a shuffled queue starting from a random track
  factory PlaybackQueue.shuffled(List<Track> allTracks) {
    final shuffled = List<Track>.from(allTracks)..shuffle();
    return PlaybackQueue(
      tracks: shuffled,
      currentIndex: 0,
      isShuffled: true,
      originalOrder: allTracks,
    );
  }

  /// Creates an ordered queue for album playback
  factory PlaybackQueue.fromAlbum(
    List<Track> albumTracks, {
    int startIndex = 0,
  }) {
    final sorted = List<Track>.from(albumTracks)
      ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
    return PlaybackQueue(
      tracks: sorted,
      currentIndex: startIndex,
      isShuffled: false,
    );
  }

  /// Creates an empty queue
  factory PlaybackQueue.empty() {
    return const PlaybackQueue(
      tracks: [],
      currentIndex: -1,
      isShuffled: false,
    );
  }

  @override
  String toString() =>
      'PlaybackQueue(tracks: ${tracks.length}, index: $currentIndex, shuffled: $isShuffled)';
}
