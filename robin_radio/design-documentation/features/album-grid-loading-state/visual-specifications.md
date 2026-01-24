---
title: Album Grid Loading State - Visual Specifications
description: Complete visual design specifications for skeleton placeholders and shimmer animation
feature: album-grid-loading-state
last-updated: 2026-01-22
version: 1.0.0
related-files:
  - ./README.md
  - ./implementation.md
dependencies:
  - Material Design 3 ColorScheme (dark theme)
  - Flutter's AnimationController
status: approved
---

# Visual Specifications

## Table of Contents
1. [Skeleton Card Specifications](#skeleton-card-specifications)
2. [Color System](#color-system)
3. [Shimmer Animation](#shimmer-animation)
4. [Layout Specifications](#layout-specifications)
5. [Transition Specifications](#transition-specifications)
6. [Accessibility](#accessibility)

---

## Skeleton Card Specifications

### Overall Card Structure

Each skeleton card replicates the exact structure of a real `AlbumCard`:

| Element | Specification |
|---------|---------------|
| Card aspect ratio | 0.72 (matches `AlbumGrid.childAspectRatio`) |
| Cover placeholder | 1:1 aspect ratio (square) |
| Title placeholder | Single line, ~70% card width |
| Artist placeholder | Single line, ~50% card width |
| Spacing between cover and title | 4px (matches real card) |

### Cover Placeholder

```
+---------------------------+
|                           |
|                           |
|    Square Placeholder     |
|    with rounded corners   |
|                           |
|                           |
+---------------------------+
```

| Property | Value |
|----------|-------|
| Shape | Square (1:1 aspect ratio) |
| Corner radius | 8px (matches `AlbumCard` ClipRRect) |
| Fill | Solid base color with shimmer overlay |

### Text Placeholders

**Title Placeholder**
| Property | Value |
|----------|-------|
| Height | 14px (approximates `bodyMedium` line height) |
| Width | 70% of card width |
| Corner radius | 4px |
| Margin top | 4px from cover |

**Artist Placeholder**
| Property | Value |
|----------|-------|
| Height | 12px (approximates `bodySmall` line height) |
| Width | 50% of card width |
| Corner radius | 4px |
| Margin top | 4px from title |

---

## Color System

### Dark Theme Skeleton Colors

The app uses Material Design 3 with a `deepPurple` seed color and `Brightness.dark`. The skeleton colors are derived from this scheme.

#### Base Colors (Static Skeleton Background)

| Token | M3 Surface Reference | Approximate Hex | Usage |
|-------|---------------------|-----------------|-------|
| `skeleton-base` | `surfaceContainerHigh` | `#2D2D3A` | Primary skeleton fill |
| `skeleton-base-alt` | `surfaceContainerHighest` | `#35354A` | Alternative/accent areas |

#### Shimmer Colors (Animation Gradient)

| Token | Description | Approximate Hex | Opacity |
|-------|-------------|-----------------|---------|
| `shimmer-base` | Gradient start/end | `#2D2D3A` | 100% |
| `shimmer-highlight` | Gradient center (moving highlight) | `#454560` | 100% |

**Gradient Structure:**
```
[shimmer-base] -> [shimmer-highlight] -> [shimmer-base]
     0%                  50%                  100%
```

### Color Derivation from ColorScheme

For implementation, use these Material 3 ColorScheme tokens:

```dart
// Base skeleton color
colorScheme.surfaceContainerHigh

// Shimmer highlight color
colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
// OR calculate a lighter variant:
Color.lerp(colorScheme.surfaceContainerHigh, colorScheme.onSurface, 0.08)
```

### Contrast Requirements

- Skeleton elements should be subtly visible against the scaffold background
- The shimmer highlight should provide clear but not harsh contrast
- Minimum contrast ratio between base and highlight: 1.2:1 (subtle distinction)

---

## Shimmer Animation

### Animation Style: Linear Gradient Sweep

A horizontal gradient sweeps across each skeleton element from left to right, creating a "shimmer" effect that indicates loading activity.

### Animation Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Duration | 1500ms (1.5 seconds) | Slow enough to feel smooth, fast enough to indicate activity |
| Easing | `Curves.easeInOut` | Smooth acceleration and deceleration |
| Repeat | Infinite loop | Continues until content loads |
| Direction | Left to right | Matches natural reading direction |

### Gradient Specifications

**Gradient Type:** LinearGradient with horizontal sweep

```dart
LinearGradient(
  begin: Alignment(-1.0 + (2.0 * animationValue), 0.0),
  end: Alignment(-0.5 + (2.0 * animationValue), 0.0),
  colors: [
    baseColor,           // shimmer-base
    highlightColor,      // shimmer-highlight
    baseColor,           // shimmer-base
  ],
  stops: [0.0, 0.5, 1.0],
)
```

**Animation Value Range:** 0.0 to 1.0 (maps to full left-to-right sweep)

### Shimmer Behavior

1. **Start Position**: Highlight begins fully off-screen to the left
2. **Sweep**: Highlight moves horizontally across the element
3. **End Position**: Highlight exits fully off-screen to the right
4. **Loop**: Animation restarts immediately (no pause)

### Visual Timing Diagram

```
Time 0ms      Time 750ms     Time 1500ms
[===      ]   [   ===   ]    [      ===]
Highlight     Highlight      Highlight
at start      at center      at end
```

### Synchronized vs. Staggered Animation

**Recommendation: Synchronized Animation**

All skeleton cards animate together with the same timing. This creates a unified, calm loading state rather than a chaotic multi-element dance.

If staggered animation is preferred for variety:
- Stagger offset: 100ms per card
- Maximum stagger: 500ms (so cards 6+ start with card 5)

---

## Layout Specifications

### Grid Configuration

| Property | Mobile (<400px) | Tablet (400-600px) | Desktop (>600px) |
|----------|-----------------|---------------------|-------------------|
| Columns | 2 | 3 | 4+ |
| Padding | 16px all sides | 16px all sides | 16px all sides |
| Cross-axis spacing | 16px | 16px | 16px |
| Main-axis spacing | 16px | 16px | 16px |

### Skeleton Count

| Viewport | Recommended Count | Rationale |
|----------|-------------------|-----------|
| Mobile (2 columns) | 6 skeletons | Fills ~2 rows visible in viewport |
| Tablet (3 columns) | 6 skeletons | Fills 2 rows |
| Desktop (4 columns) | 8 skeletons | Fills 2 rows |

**Calculation Logic:**
```dart
int skeletonCount = crossAxisCount * 3; // 3 rows of skeletons
// Capped at 8 to avoid excessive rendering
skeletonCount = skeletonCount.clamp(6, 8);
```

### Viewport Fill Strategy

Skeletons should fill the visible viewport without scrolling. This provides immediate visual feedback that the entire grid area will contain content.

---

## Transition Specifications

### Skeleton to Real Content Transition

When the catalog loads successfully, real album cards should replace skeletons with a smooth transition.

#### Option A: Fade Crossfade (Recommended)

| Property | Value |
|----------|-------|
| Duration | 300ms |
| Easing | `Curves.easeOut` |
| Behavior | Skeletons fade out while real cards fade in simultaneously |

**Implementation Approach:**
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  child: isLoading ? SkeletonGrid() : AlbumGrid(),
)
```

#### Option B: Per-Card Staggered Reveal

Each real card fades in individually with a slight delay.

| Property | Value |
|----------|-------|
| Per-card duration | 200ms |
| Stagger delay | 50ms per card |
| Maximum total time | 500ms (first 10 cards) |

**Use Case:** More dynamic feel, but adds complexity.

### Image Loading State (Post-Skeleton)

The current `AlbumCard` implementation already handles the image loading state:
- Greyscale filter + 60% opacity while image loads
- Circular progress indicator on cover
- Fade to full color when image is ready

**Design Continuity:** The skeleton state is distinct from the image-loading state:
1. **Skeleton**: No content yet, shape placeholders only
2. **Album Card (loading)**: Real metadata visible, greyscale cover with spinner
3. **Album Card (loaded)**: Full color, interactive

---

## Accessibility

### Screen Reader Announcements

When the skeleton grid is displayed, provide context for screen reader users.

**Semantic Label for Skeleton Grid:**
```
"Loading albums, please wait"
```

**Implementation:**
```dart
Semantics(
  label: 'Loading albums, please wait',
  child: SkeletonGrid(...),
)
```

### Reduced Motion Support

Respect the user's system preference for reduced motion.

**When `MediaQuery.disableAnimations` is true:**
- Disable shimmer animation
- Show static skeleton placeholders (no movement)
- Use a subtle pulse (opacity 0.7 to 1.0) as an alternative indicator

**Reduced Motion Alternative:**
```dart
if (MediaQuery.of(context).disableAnimations) {
  // Use static skeleton with subtle opacity pulse
  AnimatedOpacity(
    duration: Duration(milliseconds: 800),
    opacity: pulseValue, // 0.7 to 1.0
    child: StaticSkeleton(),
  )
}
```

### Color Contrast

Skeleton placeholders do not require WCAG contrast compliance since they contain no text content. However, they should be clearly distinguishable from the background to indicate that content will appear.

### Focus Management

- Skeleton elements should not be focusable
- When content loads, focus should remain at the current position (no forced focus change)
- The first loaded album card should be focusable for keyboard navigation

---

## Design Tokens Summary

For easy implementation reference, here are all design tokens in one place:

### Colors
```dart
// Skeleton base (static background)
final skeletonBase = colorScheme.surfaceContainerHigh;

// Shimmer highlight (moving gradient center)
final shimmerHighlight = Color.lerp(
  colorScheme.surfaceContainerHigh,
  colorScheme.onSurface,
  0.1,
)!;
```

### Dimensions
```dart
const double coverBorderRadius = 8.0;
const double textPlaceholderRadius = 4.0;
const double titlePlaceholderHeight = 14.0;
const double artistPlaceholderHeight = 12.0;
const double titleWidthPercent = 0.70;
const double artistWidthPercent = 0.50;
const double spacingCoverToTitle = 4.0;
const double spacingTitleToArtist = 4.0;
```

### Animation
```dart
const Duration shimmerDuration = Duration(milliseconds: 1500);
const Curve shimmerCurve = Curves.easeInOut;
const Duration transitionDuration = Duration(milliseconds: 300);
const Curve transitionCurve = Curves.easeOut;
```

### Layout
```dart
const int minSkeletonCount = 6;
const int maxSkeletonCount = 8;
const double gridPadding = 16.0;
const double gridSpacing = 16.0;
```
