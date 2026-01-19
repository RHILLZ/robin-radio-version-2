import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/widgets/player_controls.dart';

void main() {
  group('PlayerControls', () {
    testWidgets('displays play button when not playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('displays pause button when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              isLoading: true,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onPlayPause when play/pause button tapped',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () => tapped = true,
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(tapped, isTrue);
    });

    testWidgets('calls onSkipNext when skip next button tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_next));
      expect(tapped, isTrue);
    });

    testWidgets('calls onSkipPrevious when skip previous button tapped',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () => tapped = true,
              onSkipNext: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_previous));
      expect(tapped, isTrue);
    });

    testWidgets('disables skip previous button when canSkipPrevious is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: false,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      // Find the skip previous button and verify it's disabled
      final button = find.ancestor(
        of: find.byIcon(Icons.skip_previous),
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(button);
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('disables skip next button when canSkipNext is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: false,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      // Find the skip next button and verify it's disabled
      final button = find.ancestor(
        of: find.byIcon(Icons.skip_next),
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(button);
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('has semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      // Verify semantic labels exist
      expect(
        find.bySemanticsLabel('Play'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Skip to previous track'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Skip to next track'),
        findsOneWidget,
      );
    });

    testWidgets('has pause semantic label when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Pause'),
        findsOneWidget,
      );
    });
  });
}
