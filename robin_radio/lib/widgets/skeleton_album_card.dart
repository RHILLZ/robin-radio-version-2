import 'package:flutter/material.dart';

/// A skeleton placeholder card that mimics the AlbumCard layout
///
/// Shows animated shimmer placeholders for album cover, title, and artist
/// while the actual catalog data is loading from Firebase.
class SkeletonAlbumCard extends StatefulWidget {
  const SkeletonAlbumCard({super.key});

  @override
  State<SkeletonAlbumCard> createState() => _SkeletonAlbumCardState();
}

class _SkeletonAlbumCardState extends State<SkeletonAlbumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Loading album',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album cover placeholder - square aspect ratio
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return _ShimmerBox(
                    shimmerValue: _shimmerAnimation.value,
                    baseColor: colorScheme.surfaceContainerHighest,
                    highlightColor: _lightenColor(
                      colorScheme.surfaceContainerHighest,
                      0.12,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Title placeholder - ~60% width
          Flexible(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: 0.6,
                  child: _ShimmerBox(
                    shimmerValue: _shimmerAnimation.value,
                    baseColor: colorScheme.surfaceContainerHighest,
                    highlightColor: _lightenColor(
                      colorScheme.surfaceContainerHighest,
                      0.12,
                    ),
                    height: 14,
                    borderRadius: 4,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // Artist placeholder - ~40% width
          Flexible(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: 0.4,
                  child: _ShimmerBox(
                    shimmerValue: _shimmerAnimation.value,
                    baseColor: colorScheme.surfaceContainerHighest,
                    highlightColor: _lightenColor(
                      colorScheme.surfaceContainerHighest,
                      0.12,
                    ),
                    height: 12,
                    borderRadius: 4,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lightens a color by the given amount (0.0 to 1.0)
  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// A box with animated shimmer gradient effect
class _ShimmerBox extends StatelessWidget {
  final double shimmerValue;
  final Color baseColor;
  final Color highlightColor;
  final double? height;
  final double borderRadius;

  const _ShimmerBox({
    required this.shimmerValue,
    required this.baseColor,
    required this.highlightColor,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
          stops: [
            (shimmerValue - 0.3).clamp(0.0, 1.0),
            shimmerValue.clamp(0.0, 1.0),
            (shimmerValue + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

/// A grid of skeleton album cards for loading state
///
/// Displays placeholder cards in the same layout as AlbumGrid
/// while the catalog is loading.
class SkeletonAlbumGrid extends StatelessWidget {
  /// Number of skeleton cards to display
  final int itemCount;

  const SkeletonAlbumGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateColumnCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Same aspect ratio as AlbumGrid
            childAspectRatio: 0.72,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => const SkeletonAlbumCard(),
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
