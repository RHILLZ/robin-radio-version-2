import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'player_screen.dart';
import 'search_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _navigateToSearch(context),
            tooltip: 'Search',
          ),
        ],
      ),
      body: _buildBody(context, ref, catalogState, playbackState),
      bottomNavigationBar: MiniPlayer(
        onTap: playbackState.currentTrack != null
            ? () => _navigateToPlayer(context, playbackState.currentTrack!)
            : null,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CatalogState catalogState,
    PlaybackState playbackState,
  ) {
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

    // Empty catalog state - only show when done loading and truly empty
    if (!catalogState.isLoading && catalogState.tracks.isEmpty) {
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

    // Show content - Radio button and album grid (even while loading)
    return Column(
      children: [
        // Offline indicator at top
        const OfflineIndicator(),
        // Radio button section at top
        _RadioSection(
          catalogState: catalogState,
          playbackState: playbackState,
          onRadioTap: () => _startRadioMode(ref, catalogState),
        ),
        // Album grid fills remaining space with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(catalogProvider.notifier).refresh(),
            child: AlbumGrid(
              albums: catalogState.albums,
              onAlbumTap: (album) => _navigateToAlbum(context, album),
              isLoading: catalogState.isLoading,
            ),
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

  void _navigateToPlayer(BuildContext context, Track track) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(track: track),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
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

    // Build status text based on loading state
    String statusText;
    if (catalogState.hasMoreToLoad) {
      // Still loading more albums - show progress
      statusText = '${catalogState.albums.length} albums found...';
    } else if (catalogState.isLoading) {
      // Just started loading, no albums yet
      statusText = 'Loading...';
    } else {
      // Done loading - show final counts
      statusText =
          '${catalogState.tracks.length} songs \u2022 ${catalogState.albums.length} albums';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row - shows progressive count while loading
          Text(
            statusText,
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
