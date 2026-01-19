import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'player_screen.dart';

/// Search screen for finding music
///
/// Provides a search bar and results list. Supports fuzzy matching
/// so Mom can find music even with typos.
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final catalogState = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBarWidget(
              autofocus: true,
              onChanged: (query) {
                ref.read(searchProvider.notifier).search(query);
              },
              onClear: () {
                ref.read(searchProvider.notifier).clear();
              },
            ),
          ),
          // Results or empty state
          Expanded(
            child: _buildContent(context, ref, searchState, catalogState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SearchState searchState,
    CatalogState catalogState,
  ) {
    // If no query, show instructions
    if (!searchState.hasQuery) {
      return _SearchInstructions();
    }

    // Show results (or no results message)
    return SearchResults(
      results: searchState.results,
      query: searchState.query,
      onResultTap: (result) => _handleResultTap(context, ref, result),
    );
  }

  void _handleResultTap(
    BuildContext context,
    WidgetRef ref,
    SearchResult result,
  ) {
    switch (result.type) {
      case SearchResultType.artist:
        // Navigate to first album by this artist
        final catalogState = ref.read(catalogProvider);
        final albums = catalogState.albums
            .where((a) => a.artistId == result.artist?.id)
            .toList();
        if (albums.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlbumScreen(album: albums.first),
            ),
          );
        }
        break;

      case SearchResultType.album:
        if (result.album != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlbumScreen(album: result.album!),
            ),
          );
        }
        break;

      case SearchResultType.track:
        if (result.track != null) {
          // Start playing the track
          ref.read(playbackProvider.notifier).playTrack(result.track!);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlayerScreen(track: result.track!),
            ),
          );
        }
        break;
    }
  }
}

/// Instructions shown when search bar is empty
class _SearchInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for music',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Find songs, albums, or artists',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
