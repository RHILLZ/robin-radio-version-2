import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';

/// Main home screen for Robin Radio
///
/// Shows prominent Radio button at top, album grid below, and MiniPlayer at bottom.
/// Mom can either shuffle all music or browse albums.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final playbackState = ref.watch(playbackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robin Radio'),
        centerTitle: true,
      ),
      body: _buildBody(context, ref, catalogState, playbackState),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CatalogState catalogState,
    PlaybackState playbackState,
  ) {
    // Loading state
    if (catalogState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your music...'),
          ],
        ),
      );
    }

    // Error state
    if (catalogState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                catalogState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(catalogProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty catalog state
    if (catalogState.tracks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No music found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add albums to your Firebase Storage to get started',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Normal state with content - Radio button and album grid
    return Column(
      children: [
        // Radio button section at top
        _RadioSection(
          catalogState: catalogState,
          playbackState: playbackState,
          onRadioTap: () => _startRadioMode(ref, catalogState),
        ),
        // Album grid fills remaining space
        Expanded(
          child: AlbumGrid(
            albums: catalogState.albums,
            onAlbumTap: (album) => _navigateToAlbum(context, album),
          ),
        ),
        // Error message if playback failed
        if (playbackState.error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              playbackState.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  void _startRadioMode(WidgetRef ref, CatalogState catalogState) {
    ref.read(playbackProvider.notifier).playShuffled(catalogState.tracks);
  }

  void _navigateToAlbum(BuildContext context, Album album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumScreen(album: album),
      ),
    );
  }
}

/// Radio section with button and stats
class _RadioSection extends StatelessWidget {
  final CatalogState catalogState;
  final PlaybackState playbackState;
  final VoidCallback onRadioTap;

  const _RadioSection({
    required this.catalogState,
    required this.playbackState,
    required this.onRadioTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row
          Text(
            '${catalogState.tracks.length} songs • ${catalogState.albums.length} albums',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Radio button
          RadioButton(
            onPressed: onRadioTap,
            isLoading: playbackState.isLoading && !playbackState.hasTrack,
          ),
        ],
      ),
    );
  }
}
