import 'package:flutter/material.dart';

import '../models/models.dart';
import 'track_list_item.dart';

/// A scrollable list of tracks
///
/// Displays track information and highlights the currently playing track.
class TrackList extends StatelessWidget {
  final List<Track> tracks;
  final void Function(int index) onTrackTap;
  final String? currentTrackId;

  const TrackList({
    super.key,
    required this.tracks,
    required this.onTrackTap,
    this.currentTrackId,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'No tracks',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying = currentTrackId == track.id;

        return TrackListItem(
          track: track,
          onTap: () => onTrackTap(index),
          isPlaying: isPlaying,
        );
      },
    );
  }
}
