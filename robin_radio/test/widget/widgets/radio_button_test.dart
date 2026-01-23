import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/widgets/radio_button.dart';

void main() {
  group('RadioButton', () {
    testWidgets('renders button when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(onToggle: () {}),
          ),
        ),
      );

      expect(find.byType(RadioButton), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('does not show loading indicator when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides icon when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // When loading, icon is replaced with loading indicator
      expect(find.byIcon(Icons.power_settings_new), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has semantic label for "off" state (not playing)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RadioButton));
      expect(semantics.label, contains('Radio is off'));
    });

    testWidgets('has semantic label for "on" state (playing)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: true,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RadioButton));
      expect(semantics.label, contains('Radio is on'));
    });

    testWidgets('has minimum touch target size of 48x48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadioButton(onToggle: () {}),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(RadioButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('button has correct size (80x80)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadioButton(onToggle: () {}),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(RadioButton));
      expect(size.width, equals(80.0));
      expect(size.height, equals(80.0));
    });

    testWidgets('loading indicator maintains button size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadioButton(
                onToggle: () {},
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      // The loading container should be 80x80 to match the button size
      final size = tester.getSize(find.byType(RadioButton));
      expect(size.width, equals(80.0));
      expect(size.height, equals(80.0));
    });

    testWidgets('isPlaying state is passed correctly', (tester) async {
      // Test isPlaying = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      var semantics = tester.getSemantics(find.byType(RadioButton));
      expect(semantics.label, contains('Radio is off'));

      // Test isPlaying = true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: true,
            ),
          ),
        ),
      );

      semantics = tester.getSemantics(find.byType(RadioButton));
      expect(semantics.label, contains('Radio is on'));
    });

    testWidgets('transitions between loading and non-loading states', (tester) async {
      // Start with loading
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new), findsNothing);

      // Transition to non-loading
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      var onToggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () => onToggleCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RadioButton));
      await tester.pump();

      expect(onToggleCalled, isTrue);
    });

    testWidgets('does not call onToggle when loading', (tester) async {
      var onToggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () => onToggleCalled = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RadioButton));
      await tester.pump();

      expect(onToggleCalled, isFalse);
    });

    testWidgets('shows gray icon when off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      // Let animations settle
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new));
      expect(icon.color, equals(const Color(0xFF666666)));
    });

    testWidgets('shows pink icon when on', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: true,
            ),
          ),
        ),
      );

      // Let animations settle
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new));
      expect(icon.color, equals(const Color(0xFFFF0083)));
    });

    testWidgets('button visual state syncs with isPlaying changes', (tester) async {
      // Start with off state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new));
      expect(icon.color, equals(const Color(0xFF666666)));

      // Change to on state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new));
      expect(icon.color, equals(const Color(0xFFFF0083)));

      // Change back to off state (simulates external stop like MiniPlayer)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onToggle: () {},
              isPlaying: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new));
      expect(icon.color, equals(const Color(0xFF666666)));
    });
  });
}
