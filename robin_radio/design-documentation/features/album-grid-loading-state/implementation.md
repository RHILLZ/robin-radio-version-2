---
title: Album Grid Loading State - Implementation Guide
description: Developer handoff documentation for implementing skeleton loading state
feature: album-grid-loading-state
last-updated: 2026-01-22
version: 1.0.0
related-files:
  - ./README.md
  - ./visual-specifications.md
dependencies:
  - Flutter 3.x
  - Material Design 3
  - shimmer package (optional) or custom implementation
status: approved
---

# Implementation Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Component Structure](#component-structure)
3. [Implementation Approach](#implementation-approach)
4. [Code Structure Recommendations](#code-structure-recommendations)
5. [State Management Integration](#state-management-integration)
6. [Testing Considerations](#testing-considerations)
7. [Performance Notes](#performance-notes)

---

## Architecture Overview

### Component Hierarchy

```
HomeScreen
  └── Column
        ├── OfflineIndicator
        ├── _RadioSection (stats show "Loading..." during load)
        └── Expanded
              └── RefreshIndicator
                    └── AlbumGrid
                          ├── [isLoading=true] → SkeletonAlbumGrid
                          └── [isLoading=false] → GridView of AlbumCards
```

### Files to Modify/Create

| File | Action | Purpose |
|------|--------|---------|
| `lib/widgets/skeleton_album_card.dart` | Create | Individual skeleton card widget |
| `lib/widgets/skeleton_album_grid.dart` | Create | Grid of skeleton cards |
| `lib/widgets/album_grid.dart` | Modify | Add loading state handling |
| `lib/screens/home_screen.dart` | Modify | Pass loading state to AlbumGrid |

---

## Component Structure

### SkeletonAlbumCard

A single skeleton placeholder that mirrors the `AlbumCard` structure.

**Props:**
- None required (pure presentational component)

**Structure:**
```
SkeletonAlbumCard
  └── Column
        ├── AspectRatio (1:1)
        │     └── ClipRRect (8px radius)
        │           └── ShimmerContainer (cover placeholder)
        ├── SizedBox (4px)
        ├── ShimmerContainer (title placeholder, 70% width, 14px height)
        └── ShimmerContainer (artist placeholder, 50% width, 12px height)
```

### SkeletonAlbumGrid

Grid container for multiple skeleton cards.

**Props:**
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `itemCount` | int | 6 | Number of skeleton cards to display |

**Behavior:**
- Uses same `LayoutBuilder` logic as `AlbumGrid` for responsive columns
- Renders `itemCount` skeleton cards
- All cards share the same animation controller for synchronized shimmer

### ShimmerEffect (Utility Widget)

Reusable shimmer animation wrapper.

**Props:**
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `child` | Widget | required | The skeleton shape to animate |
| `baseColor` | Color | from theme | Background color |
| `highlightColor` | Color | from theme | Shimmer highlight color |

---

## Implementation Approach

### Option A: Custom Shimmer Implementation (Recommended)

Build the shimmer effect using Flutter's `AnimationController` and `LinearGradient`. This avoids external dependencies and gives full control over the animation.

**Advantages:**
- No external dependencies
- Full control over animation timing and colors
- Smaller bundle size
- Easy to customize for dark theme

**Implementation Pattern:**

```dart
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Check for reduced motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return widget.child; // Static skeleton, no animation
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (2.0 * _controller.value), 0.0),
              end: Alignment(0.0 + (2.0 * _controller.value), 0.0),
              colors: [
                colorScheme.surfaceContainerHigh,
                Color.lerp(
                  colorScheme.surfaceContainerHigh,
                  colorScheme.onSurface,
                  0.1,
                )!,
                colorScheme.surfaceContainerHigh,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
```

### Option B: Using `shimmer` Package

The `shimmer` package provides a ready-made solution.

**pubspec.yaml:**
```yaml
dependencies:
  shimmer: ^3.0.0
```

**Usage:**
```dart
import 'package:shimmer/shimmer.dart';

Shimmer.fromColors(
  baseColor: colorScheme.surfaceContainerHigh,
  highlightColor: Color.lerp(
    colorScheme.surfaceContainerHigh,
    colorScheme.onSurface,
    0.1,
  )!,
  child: SkeletonAlbumCard(),
)
```

**Note:** If using the `shimmer` package, ensure the colors are derived from the theme's ColorScheme, not hardcoded values.

---

## Code Structure Recommendations

### SkeletonAlbumCard Implementation

```dart
// lib/widgets/skeleton_album_card.dart

import 'package:flutter/material.dart';

/// A skeleton placeholder for an album card during loading.
/// Mirrors the structure of [AlbumCard] with placeholder shapes.
class SkeletonAlbumCard extends StatelessWidget {
  const SkeletonAlbumCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHigh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover placeholder (square)
        AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(color: baseColor),
          ),
        ),
        const SizedBox(height: 4),
        // Title placeholder
        FractionallySizedBox(
          widthFactor: 0.70,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Artist placeholder
        FractionallySizedBox(
          widthFactor: 0.50,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
```

### SkeletonAlbumGrid Implementation

```dart
// lib/widgets/skeleton_album_grid.dart

import 'package:flutter/material.dart';
import 'skeleton_album_card.dart';

/// A grid of skeleton album cards shown during catalog loading.
class SkeletonAlbumGrid extends StatefulWidget {
  final int itemCount;

  const SkeletonAlbumGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  State<SkeletonAlbumGrid> createState() => _SkeletonAlbumGridState();
}

class _SkeletonAlbumGridState extends State<SkeletonAlbumGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  int _calculateColumnCount(double width) {
    if (width < 400) return 2;
    if (width < 600) return 3;
    if (width < 900) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'Loading albums, please wait',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calculateColumnCount(constraints.maxWidth);

          return AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) {
                  if (reduceMotion) {
                    return LinearGradient(
                      colors: [colorScheme.surfaceContainerHigh],
                    ).createShader(bounds);
                  }

                  return LinearGradient(
                    begin: Alignment(-1.0 + (2.0 * _shimmerController.value), 0.0),
                    end: Alignment(0.0 + (2.0 * _shimmerController.value), 0.0),
                    colors: [
                      colorScheme.surfaceContainerHigh,
                      Color.lerp(
                        colorScheme.surfaceContainerHigh,
                        colorScheme.onSurface,
                        0.1,
                      )!,
                      colorScheme.surfaceContainerHigh,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                child: child,
              );
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: widget.itemCount,
              itemBuilder: (context, index) => const SkeletonAlbumCard(),
            ),
          );
        },
      ),
    );
  }
}
```

### Modified AlbumGrid

```dart
// lib/widgets/album_grid.dart (modifications)

import 'package:flutter/material.dart';
import '../models/models.dart';
import 'album_card.dart';
import 'skeleton_album_grid.dart';

class AlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final void Function(Album album) onAlbumTap;
  final bool isLoading; // NEW: Add loading state prop

  const AlbumGrid({
    super.key,
    required this.albums,
    required this.onAlbumTap,
    this.isLoading = false, // NEW: Default to not loading
  });

  @override
  Widget build(BuildContext context) {
    // NEW: Show skeleton grid while loading
    if (isLoading && albums.isEmpty) {
      return const SkeletonAlbumGrid(itemCount: 6);
    }

    if (albums.isEmpty) {
      return const SizedBox.shrink();
    }

    // Existing grid implementation...
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateColumnCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
```

### Modified HomeScreen

```dart
// lib/screens/home_screen.dart (in _buildBody method)

// Change this line:
child: AlbumGrid(
  albums: catalogState.albums,
  onAlbumTap: (album) => _navigateToAlbum(context, album),
),

// To this:
child: AlbumGrid(
  albums: catalogState.albums,
  onAlbumTap: (album) => _navigateToAlbum(context, album),
  isLoading: catalogState.isLoading, // NEW: Pass loading state
),
```

---

## State Management Integration

### Riverpod Provider Usage

The `catalogProvider` already exposes `isLoading` state:

```dart
final catalogState = ref.watch(catalogProvider);

// catalogState.isLoading - true while fetching
// catalogState.albums - empty array until loaded
// catalogState.error - null unless error occurred
```

### State Transition Flow

```
App Start
    ↓
catalogState.isLoading = true
catalogState.albums = []
    ↓
[SkeletonAlbumGrid displayed]
    ↓
Catalog fetch completes
    ↓
catalogState.isLoading = false
catalogState.albums = [album1, album2, ...]
    ↓
[AlbumGrid with real AlbumCards displayed]
    ↓
Each AlbumCard has its own image loading state
(greyscale until cover image loads)
```

---

## Testing Considerations

### Widget Tests

```dart
testWidgets('shows skeleton grid while loading', (tester) async {
  // Mock provider with isLoading = true
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogProvider.overrideWith((ref) => MockCatalogNotifier(
          CatalogState(isLoading: true),
        )),
      ],
      child: MaterialApp(home: HomeScreen()),
    ),
  );

  expect(find.byType(SkeletonAlbumGrid), findsOneWidget);
  expect(find.byType(SkeletonAlbumCard), findsNWidgets(6));
});

testWidgets('transitions from skeleton to albums', (tester) async {
  // Start with loading state
  final notifier = MockCatalogNotifier(CatalogState(isLoading: true));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [catalogProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(home: HomeScreen()),
    ),
  );

  expect(find.byType(SkeletonAlbumGrid), findsOneWidget);

  // Simulate load complete
  notifier.state = CatalogState(
    isLoading: false,
    albums: [testAlbum1, testAlbum2],
  );

  await tester.pumpAndSettle();

  expect(find.byType(SkeletonAlbumGrid), findsNothing);
  expect(find.byType(AlbumCard), findsNWidgets(2));
});
```

### Accessibility Tests

```dart
testWidgets('skeleton grid has accessibility label', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: SkeletonAlbumGrid()),
  );

  final semantics = tester.getSemantics(find.byType(SkeletonAlbumGrid));
  expect(semantics.label, 'Loading albums, please wait');
});

testWidgets('respects reduced motion preference', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: SkeletonAlbumGrid()),
    ),
  );

  // Verify no shimmer animation is running
  // (Implementation-specific assertion)
});
```

---

## Performance Notes

### Animation Optimization

1. **Single Animation Controller**: Use one controller for the entire grid, not per-card
2. **Shader Caching**: The LinearGradient shader is recreated each frame; consider caching if performance issues arise
3. **Physics**: `NeverScrollableScrollPhysics()` on skeleton grid prevents scroll gesture conflicts

### Memory Considerations

- Skeleton cards are stateless and lightweight
- The shimmer animation uses minimal resources (single animation controller)
- Dispose the animation controller properly when the widget unmounts

### Build Performance

- Skeleton count is fixed (6-8), so layout calculations are minimal
- No network calls or async operations during skeleton display
- GridView.builder only builds visible items (though all 6-8 are likely visible)

---

## Checklist for Implementation

- [ ] Create `lib/widgets/skeleton_album_card.dart`
- [ ] Create `lib/widgets/skeleton_album_grid.dart`
- [ ] Add `isLoading` prop to `AlbumGrid`
- [ ] Update `HomeScreen` to pass `isLoading` to `AlbumGrid`
- [ ] Update `lib/widgets/widgets.dart` barrel file with new exports
- [ ] Write widget tests for skeleton display and transition
- [ ] Test on actual device for animation smoothness
- [ ] Verify accessibility with TalkBack/VoiceOver
- [ ] Test reduced motion preference handling
- [ ] Update any documentation as needed
