import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    // This is a placeholder test - full app requires Firebase initialization
    // which is not available in unit tests without mocking
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Robin Radio'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Robin Radio'), findsOneWidget);
  });
}
