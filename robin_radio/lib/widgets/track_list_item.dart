import 'package:flutter/material.dart';

import '../models/models.dart';

/// A single track item in a track list
///
/// Shows track number (or playing indicator), title, and duration.
class TrackListItem extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final bool isPlaying;

  const TrackListItem({
    super.key,
    required this.track,
    required this.onTap,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${track.title}, track ${track.trackNumber}',
      button: true,
      child: ListTile(
        onTap: onTap,
        leading: _TrackNumberOrIndicator(
          trackNumber: track.trackNumber,
          isPlaying: isPlaying,
          colorScheme: colorScheme,
        ),
        title: Text(
          track.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isPlaying ? colorScheme.primary : null,
            fontWeight: isPlaying ? FontWeight.w600 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDuration(track.duration),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? durationSeconds) {
    if (durationSeconds == null) return '--:--';

    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TrackNumberOrIndicator extends StatelessWidget {
  final int trackNumber;
  final bool isPlaying;
  final ColorScheme colorScheme;

  const _TrackNumberOrIndicator({
    required this.trackNumber,
    required this.isPlaying,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: isPlaying
            ? Icon(
                Icons.equalizer,
                color: colorScheme.primary,
                size: 20,
              )
            : Text(
                trackNumber.toString(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
