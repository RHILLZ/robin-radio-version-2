import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';

/// A compact player bar showing current track info and basic controls
///
/// Designed to be visible at the bottom of screens while browsing,
/// giving Mom constant feedback about what's playing.
class MiniPlayer extends ConsumerWidget {
  /// Optional callback when the mini player is tapped (to expand to full player)
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);
    final currentTrack = playbackState.currentTrack;

    // Don't show if nothing is playing
    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    return _MiniPlayerContent(
      track: currentTrack,
      isPlaying: playbackState.isPlaying,
      isLoading: playbackState.isLoading,
      progress: playbackState.progress,
      onTap: onTap,
      onPlayPause: () {
        ref.read(playbackProvider.notifier).togglePlayPause();
      },
      onSkipNext: playbackState.hasNext
          ? () => ref.read(playbackProvider.notifier).skipNext()
          : null,
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isLoading;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipNext;

  const _MiniPlayerContent({
    required this.track,
    required this.isPlaying,
    required this.isLoading,
    required this.progress,
    this.onTap,
    required this.onPlayPause,
    this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Now playing: ${track.title} by ${track.artistName}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar at top
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          // Main content
          Material(
            color: colorScheme.surfaceContainerHigh,
            child: InkWell(
              onTap: onTap,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Album art
                      _AlbumArt(coverUrl: track.coverUrl),
                      const SizedBox(width: 12),
                      // Track info
                      Expanded(
                        child: _TrackInfo(
                          title: track.title,
                          artist: track.artistName,
                        ),
                      ),
                      // Controls
                      _PlaybackControls(
                        isPlaying: isPlaying,
                        isLoading: isLoading,
                        onPlayPause: onPlayPause,
                        onSkipNext: onSkipNext,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String coverUrl;

  const _AlbumArt({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 48,
        height: 48,
        child: coverUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.album,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.album,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.album,
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

  const _TrackInfo({
    required this.title,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          artist,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipNext;

  const _PlaybackControls({
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPause,
    this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        Semantics(
          button: true,
          label: isPlaying ? 'Pause' : 'Play',
          child: IconButton(
            onPressed: onPlayPause,
            icon: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurface,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
          ),
        ),
        // Skip next button
        if (onSkipNext != null)
          Semantics(
            button: true,
            label: 'Skip to next track',
            child: IconButton(
              onPressed: onSkipNext,
              icon: const Icon(Icons.skip_next),
            ),
          ),
      ],
    );
  }
}
