import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'player_screen.dart';

/// Screen displaying album details with cover and track list
///
/// Shows large album artwork, album/artist info, and list of tracks.
/// Tapping a track plays the album from that position.
class AlbumScreen extends ConsumerWidget {
  final Album album;

  const AlbumScreen({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(catalogProvider.notifier).getTracksForAlbum(album.id);
    final currentTrack = ref.watch(currentTrackProvider);
    final playbackState = ref.watch(playbackProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible app bar with album cover
          _AlbumSliverAppBar(album: album),
          // Track list
          SliverFillRemaining(
            child: TrackList(
              tracks: tracks,
              currentTrackId: currentTrack?.id,
              onTrackTap: (index) => _playTrack(ref, tracks, index),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MiniPlayer(
        onTap: playbackState.currentTrack != null
            ? () => _navigateToPlayer(context, playbackState.currentTrack!)
            : null,
      ),
    );
  }

  void _playTrack(WidgetRef ref, List<Track> tracks, int index) {
    ref.read(playbackProvider.notifier).playFromAlbum(tracks, startIndex: index);
  }

  void _navigateToPlayer(BuildContext context, Track track) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(track: track),
      ),
    );
  }
}

class _AlbumSliverAppBar extends StatelessWidget {
  final Album album;

  const _AlbumSliverAppBar({required this.album});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          album.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Album cover
            _AlbumCoverImage(coverUrl: album.coverUrl, colorScheme: colorScheme),
            // Gradient overlay for readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colorScheme.surface.withValues(alpha: 0.9),
          child: Text(
            '${album.artistName} • ${album.trackCount} tracks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}

class _AlbumCoverImage extends StatelessWidget {
  final String coverUrl;
  final ColorScheme colorScheme;

  const _AlbumCoverImage({
    required this.coverUrl,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.album,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
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
