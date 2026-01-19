import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/widgets/search_bar.dart';

void main() {
  group('SearchBarWidget', () {
    testWidgets('displays text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
              hintText: 'Search music...',
            ),
          ),
        ),
      );

      expect(find.text('Search music...'), findsOneWidget);
    });

    testWidgets('calls onChanged when typing', (tester) async {
      String? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (value) => lastValue = value,
              onClear: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Beatles');
      expect(lastValue, equals('Beatles'));
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Beatles');
      await tester.pump();

      // Now clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('calls onClear when clear button tapped', (tester) async {
      var cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Beatles');
      await tester.pump();

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('clears text field when clear button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Beatles');
      await tester.pump();

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Text field should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('autofocus is configurable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
              autofocus: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('has accessibility label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('search', caseSensitive: false)),
        findsOneWidget,
      );
    });
  });
}
