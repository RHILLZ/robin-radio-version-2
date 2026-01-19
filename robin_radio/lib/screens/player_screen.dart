import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/player_controls.dart';

/// Full-screen player with large album art and playback controls
///
/// Shows album artwork, track info, progress bar, and full controls.
/// Designed for focused playback experience.
class PlayerScreen extends ConsumerWidget {
  final Track track;

  const PlayerScreen({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'Now Playing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Album artwork
                      _AlbumArtwork(
                        coverUrl: playbackState.currentTrack?.coverUrl ?? track.coverUrl,
                      ),
                      const SizedBox(height: 32),
                      // Track info
                      _TrackInfo(
                        title: playbackState.currentTrack?.title ?? track.title,
                        artist: playbackState.currentTrack?.artistName ?? track.artistName,
                        album: playbackState.currentTrack?.albumTitle ?? track.albumTitle,
                      ),
                      const SizedBox(height: 24),
                      // Progress bar
                      _ProgressBar(
                        position: playbackState.position,
                        duration: playbackState.duration,
                        onSeek: (progress) {
                          ref.read(playbackProvider.notifier).seekToProgress(progress);
                        },
                      ),
                      const SizedBox(height: 24),
                      // Playback controls
                      PlayerControls(
                        isPlaying: playbackState.isPlaying,
                        isLoading: playbackState.isLoading,
                        canSkipPrevious: playbackState.hasPrevious,
                        canSkipNext: playbackState.hasNext,
                        onPlayPause: () {
                          ref.read(playbackProvider.notifier).togglePlayPause();
                        },
                        onSkipPrevious: () {
                          ref.read(playbackProvider.notifier).skipPrevious();
                        },
                        onSkipNext: () {
                          ref.read(playbackProvider.notifier).skipNext();
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlbumArtwork extends StatelessWidget {
  final String coverUrl;

  const _AlbumArtwork({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size.width - 48;

    return Container(
      width: size,
      height: size,
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: coverUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.album,
                    size: 80,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.album,
                  size: 80,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;

  const _TrackInfo({
    required this.title,
    required this.artist,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          album,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration? duration;
  final ValueChanged<double> onSeek;

  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final durationMs = duration?.inMilliseconds ?? 0;
    final positionMs = position.inMilliseconds;
    final progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Slider(
          value: progress,
          onChanged: onSeek,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.surfaceContainerHighest,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                duration != null ? _formatDuration(duration!) : '--:--',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
