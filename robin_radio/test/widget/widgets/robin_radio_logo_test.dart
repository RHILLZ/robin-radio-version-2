import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/widgets/robin_radio_logo.dart';

void main() {
  group('RobinRadioLogo', () {
    testWidgets('renders with default settings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(),
          ),
        ),
      );

      expect(find.byType(RobinRadioLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('uses icon logo by default (showText: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, 'assets/branding/logo_icon.png');
    });

    testWidgets('uses full logo when showText is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(showText: true),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, 'assets/branding/logo_full.png');
    });

    testWidgets('respects custom height', (tester) async {
      const customHeight = 60.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(height: customHeight),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.height, customHeight);
    });

    testWidgets('has default height of 40', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.height, 40);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.semanticLabel, 'Robin Radio logo');
    });

    testWidgets('uses BoxFit.contain', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RobinRadioLogo(),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('can be used in Row for AppBar title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RobinRadioLogo(height: 28),
                  SizedBox(width: 8),
                  Text('Robin Radio'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RobinRadioLogo), findsOneWidget);
      expect(find.text('Robin Radio'), findsOneWidget);
    });
  });
}
