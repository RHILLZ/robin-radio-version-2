import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import 'robin_radio_logo.dart';

/// Greyscale color matrix for ColorFiltered widget
const ColorFilter _greyscaleFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// A card displaying an album with cover image, title, and artist name
///
/// Designed for use in a grid layout, showing album artwork prominently
/// with text information below. Shows a greyed-out loading state until
/// the cover image is fully loaded.
class AlbumCard extends StatefulWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    // If no cover URL, mark as loaded immediately
    if (widget.album.coverUrl.isEmpty) {
      _imageLoaded = true;
    }
  }

  void _onImageLoaded() {
    if (mounted && !_imageLoaded) {
      setState(() {
        _imageLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Album cover
        AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _AlbumCover(
              coverUrl: widget.album.coverUrl,
              colorScheme: colorScheme,
              onImageLoaded: _onImageLoaded,
              isLoading: !_imageLoaded,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Album title
        Flexible(
          child: Text(
            widget.album.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Artist name
        Flexible(
          child: Text(
            widget.album.artistName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // Apply greyscale filter and reduced opacity when loading
    final Widget content = _imageLoaded
        ? cardContent
        : AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 0.6,
            child: ColorFiltered(
              colorFilter: _greyscaleFilter,
              child: cardContent,
            ),
          );

    return Semantics(
      label: _imageLoaded
          ? '${widget.album.title} by ${widget.album.artistName}'
          : '${widget.album.title} by ${widget.album.artistName}, loading',
      button: true,
      child: InkWell(
        // Disable tap when loading by passing null
        onTap: _imageLoaded ? widget.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}

class _AlbumCover extends StatelessWidget {
  final String coverUrl;
  final ColorScheme colorScheme;
  final VoidCallback onImageLoaded;
  final bool isLoading;

  const _AlbumCover({
    required this.coverUrl,
    required this.colorScheme,
    required this.onImageLoaded,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl.isEmpty) {
      return _PlaceholderCover(colorScheme: colorScheme);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: coverUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              _PlaceholderCover(colorScheme: colorScheme),
          errorWidget: (context, url, error) {
            // Mark as loaded on error so the card becomes tappable
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onImageLoaded();
            });
            return _PlaceholderCover(colorScheme: colorScheme);
          },
          imageBuilder: (context, imageProvider) {
            // Image is loaded, notify parent
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onImageLoaded();
            });
            return Image(image: imageProvider, fit: BoxFit.cover);
          },
        ),
        // Loading indicator overlay
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
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
      child: const Center(
        child: RobinRadioLogo(height: 48),
      ),
    );
  }
}
