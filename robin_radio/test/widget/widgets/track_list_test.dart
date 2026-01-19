import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/widgets/track_list.dart';
import 'package:robin_radio/widgets/track_list_item.dart';

void main() {
  const testTracks = <Track>[
    Track(
      id: 'track-1',
      title: 'Come Together',
      albumId: 'album-1',
      albumTitle: 'Abbey Road',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/song1.mp3',
      storagePath: 'Artists/The Beatles/Abbey Road/01 Come Together.mp3',
      trackNumber: 1,
      duration: 259,
    ),
    Track(
      id: 'track-2',
      title: 'Something',
      albumId: 'album-1',
      albumTitle: 'Abbey Road',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/song2.mp3',
      storagePath: 'Artists/The Beatles/Abbey Road/02 Something.mp3',
      trackNumber: 2,
      duration: 182,
    ),
    Track(
      id: 'track-3',
      title: 'Maxwell\'s Silver Hammer',
      albumId: 'album-1',
      albumTitle: 'Abbey Road',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/song3.mp3',
      storagePath: 'Artists/The Beatles/Abbey Road/03 Maxwell\'s Silver Hammer.mp3',
      trackNumber: 3,
      duration: 207,
    ),
  ];

  group('TrackList', () {
    testWidgets('displays all tracks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackList(
              tracks: testTracks,
              onTrackTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('Something'), findsOneWidget);
      expect(find.text("Maxwell's Silver Hammer"), findsOneWidget);
    });

    testWidgets('displays TrackListItem for each track', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackList(
              tracks: testTracks,
              onTrackTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TrackListItem), findsNWidgets(3));
    });

    testWidgets('calls onTrackTap with correct index when tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackList(
              tracks: testTracks,
              onTrackTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Something'));
      expect(tappedIndex, equals(1));
    });

    testWidgets('highlights currently playing track', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackList(
              tracks: testTracks,
              onTrackTap: (_) {},
              currentTrackId: 'track-2',
            ),
          ),
        ),
      );

      // Find the playing indicator on the second track
      final trackListItems = tester.widgetList<TrackListItem>(
        find.byType(TrackListItem),
      );

      final secondItem = trackListItems.elementAt(1);
      expect(secondItem.isPlaying, isTrue);
    });

    testWidgets('shows empty state when no tracks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackList(
              tracks: const [],
              onTrackTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TrackListItem), findsNothing);
      expect(find.text('No tracks'), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackList(
              tracks: testTracks,
              onTrackTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('TrackListItem', () {
    testWidgets('displays track number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays track title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      expect(find.text('Come Together'), findsOneWidget);
    });

    testWidgets('displays duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      // 259 seconds = 4:19
      expect(find.text('4:19'), findsOneWidget);
    });

    testWidgets('shows playing indicator when isPlaying', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () {},
              isPlaying: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.equalizer), findsOneWidget);
    });

    testWidgets('shows track number when not playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.equalizer), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () => tapped = true,
              isPlaying: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TrackListItem));
      expect(tapped, isTrue);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListItem(
              track: testTracks[0],
              onTap: () {},
              isPlaying: false,
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TrackListItem));
      expect(semantics.label, contains('Come Together'));
    });
  });
}
