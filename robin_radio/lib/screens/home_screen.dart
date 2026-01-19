import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/widgets.dart';

/// Main home screen for Robin Radio
///
/// Simple layout focused on Mom's primary use case: tap Radio and listen.
/// Shows catalog stats, prominent Radio button, and MiniPlayer at bottom.
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

    // Normal state with content
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Music stats
              _CatalogStats(
                artistCount: catalogState.artists.length,
                albumCount: catalogState.albums.length,
                trackCount: catalogState.tracks.length,
              ),
              const SizedBox(height: 48),
              // Radio button - the main action
              RadioButton(
                onPressed: () => _startRadioMode(ref, catalogState),
                isLoading: playbackState.isLoading && !playbackState.hasTrack,
              ),
              const SizedBox(height: 24),
              // Error message if playback failed
              if (playbackState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
          ),
        ),
      ),
    );
  }

  void _startRadioMode(WidgetRef ref, CatalogState catalogState) {
    ref.read(playbackProvider.notifier).playShuffled(catalogState.tracks);
  }
}

class _CatalogStats extends StatelessWidget {
  final int artistCount;
  final int albumCount;
  final int trackCount;

  const _CatalogStats({
    required this.artistCount,
    required this.albumCount,
    required this.trackCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          Icons.library_music,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '$trackCount songs',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$albumCount albums from $artistCount artists',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
