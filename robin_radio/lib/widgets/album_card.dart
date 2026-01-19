import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

/// A card displaying an album with cover image, title, and artist name
///
/// Designed for use in a grid layout, showing album artwork prominently
/// with text information below.
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${album.title} by ${album.artistName}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album cover
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _AlbumCover(
                  coverUrl: album.coverUrl,
                  colorScheme: colorScheme,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Album title
            Text(
              album.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist name
            Text(
              album.artistName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCover extends StatelessWidget {
  final String coverUrl;
  final ColorScheme colorScheme;

  const _AlbumCover({
    required this.coverUrl,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl.isEmpty) {
      return _PlaceholderCover(colorScheme: colorScheme);
    }

    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _PlaceholderCover(colorScheme: colorScheme),
      errorWidget: (context, url, error) =>
          _PlaceholderCover(colorScheme: colorScheme),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PlaceholderCover({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
