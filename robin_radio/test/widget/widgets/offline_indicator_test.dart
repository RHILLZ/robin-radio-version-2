import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/providers/connectivity_provider.dart';
import 'package:robin_radio/widgets/offline_indicator.dart';

void main() {
  group('OfflineIndicator', () {
    testWidgets('shows offline banner when not connected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(),
            ),
          ),
        ),
      );

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows nothing when connected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(),
            ),
          ),
        ),
      );

      expect(find.text('Offline Mode'), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });

    testWidgets('displays with correct styling', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Offline Mode'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container, isNotNull);
    });
  });
}
