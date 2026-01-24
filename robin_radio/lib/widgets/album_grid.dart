import 'package:flutter/material.dart';

import '../models/models.dart';
import 'album_card.dart';
import 'skeleton_album_card.dart';

/// A responsive grid of album cards
///
/// Displays albums in a grid layout that adapts to screen width,
/// showing more columns on wider screens. Shows skeleton placeholders
/// when [isLoading] is true and [albums] is empty.
class AlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final void Function(Album album) onAlbumTap;

  /// Whether the catalog is currently loading
  final bool isLoading;

  /// Number of skeleton cards to show while loading (default: 6)
  final int skeletonCount;

  const AlbumGrid({
    super.key,
    required this.albums,
    required this.onAlbumTap,
    this.isLoading = false,
    this.skeletonCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Show skeleton grid when loading and no albums yet
    if (isLoading && albums.isEmpty) {
      return SkeletonAlbumGrid(itemCount: skeletonCount);
    }

    if (albums.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate column count based on width
        // Aim for ~150px per card on mobile, ~180px on larger screens
        final crossAxisCount = _calculateColumnCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Extra height for title and artist text below square cover
            childAspectRatio: 0.72,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return AlbumCard(
              album: album,
              onTap: () => onAlbumTap(album),
            );
          },
        );
      },
    );
  }

  int _calculateColumnCount(double width) {
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 900) return 4;
    return 5;
  }
}
