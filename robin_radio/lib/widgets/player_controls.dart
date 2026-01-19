import 'package:flutter/material.dart';

/// Full playback controls for the player screen
///
/// Shows previous, play/pause, and next buttons with loading states.
/// Designed for the full-screen player, not the mini player.
class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool canSkipPrevious;
  final bool canSkipNext;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipPrevious;
  final VoidCallback onSkipNext;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.canSkipPrevious,
    required this.canSkipNext,
    required this.onPlayPause,
    required this.onSkipPrevious,
    required this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip previous button
        Semantics(
          button: true,
          label: 'Skip to previous track',
          child: IconButton(
            onPressed: canSkipPrevious ? onSkipPrevious : null,
            iconSize: 48,
            icon: Icon(
              Icons.skip_previous,
              color: canSkipPrevious
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Play/Pause button (larger, prominent)
        Semantics(
          button: true,
          label: isPlaying ? 'Pause' : 'Play',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
            child: IconButton(
              onPressed: onPlayPause,
              iconSize: 48,
              padding: const EdgeInsets.all(16),
              icon: isLoading
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: colorScheme.onPrimary,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Skip next button
        Semantics(
          button: true,
          label: 'Skip to next track',
          child: IconButton(
            onPressed: canSkipNext ? onSkipNext : null,
            iconSize: 48,
            icon: Icon(
              Icons.skip_next,
              color: canSkipNext
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ],
    );
  }
}
