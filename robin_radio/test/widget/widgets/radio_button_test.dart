import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/widgets/radio_button.dart';

void main() {
  group('RadioButton', () {
    testWidgets('renders with correct text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Radio'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(onPressed: () => pressed = true),
          ),
        ),
      );

      await tester.tap(find.byType(RadioButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is disabled when isLoading is true', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RadioButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(onPressed: () {}),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(RadioButton));
      expect(semantics.label, contains('Radio'));
    });

    testWidgets('has minimum touch target size of 48x48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RadioButton(onPressed: () {}),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(RadioButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('displays radio icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadioButton(onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.radio), findsOneWidget);
    });
  });
}
