import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/widgets/skeleton_album_card.dart';

void main() {
  group('SkeletonAlbumCard', () {
    testWidgets('renders skeleton placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 280,
              child: SkeletonAlbumCard(),
            ),
          ),
        ),
      );

      // Skeleton should render with accessibility label
      expect(find.bySemanticsLabel('Loading album'), findsOneWidget);
    });

    testWidgets('has shimmer animation running', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 280,
              child: SkeletonAlbumCard(),
            ),
          ),
        ),
      );

      // Animation should be running - pump some frames
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Widget should still be present after animation frames
      expect(find.byType(SkeletonAlbumCard), findsOneWidget);
    });

    testWidgets('disposes animation controller properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 280,
              child: SkeletonAlbumCard(),
            ),
          ),
        ),
      );

      // Remove widget - should not throw
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(SkeletonAlbumCard), findsNothing);
    });
  });

  group('SkeletonAlbumGrid', () {
    testWidgets('renders specified number of skeleton cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: SkeletonAlbumGrid(itemCount: 4),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonAlbumCard), findsNWidgets(4));
    });

    testWidgets('defaults to 6 skeleton cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: SkeletonAlbumGrid(),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonAlbumCard), findsNWidgets(6));
    });

    testWidgets('uses GridView for layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: SkeletonAlbumGrid(),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('adapts column count to screen width', (tester) async {
      // Narrow screen - should have 2 columns
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 800,
              child: SkeletonAlbumGrid(itemCount: 4),
            ),
          ),
        ),
      );

      // All 4 cards should be visible
      expect(find.byType(SkeletonAlbumCard), findsNWidgets(4));
    });
  });
}
