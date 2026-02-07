import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'firebase_options.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/catalog_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio playback support
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.robinradio.channel.audio',
    androidNotificationChannelName: 'Robin Radio',
    androidNotificationOngoing: true,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Generate a unique session token for this app launch.
  // Each cold start gets a new token, so the catalog cache is only
  // reused within the same session (not across restarts).
  final sessionToken = DateTime.now().microsecondsSinceEpoch.toString();
  final catalogCacheService = CatalogCacheService(sessionToken: sessionToken);

  runApp(
    ProviderScope(
      overrides: [
        catalogCacheServiceProvider.overrideWithValue(catalogCacheService),
      ],
      child: const RobinRadioApp(),
    ),
  );
}

class RobinRadioApp extends ConsumerStatefulWidget {
  const RobinRadioApp({super.key});

  @override
  ConsumerState<RobinRadioApp> createState() => _RobinRadioAppState();
}

class _RobinRadioAppState extends ConsumerState<RobinRadioApp> {
  @override
  void initState() {
    super.initState();
    // Load catalog on app start
    Future.microtask(() {
      ref.read(catalogProvider.notifier).loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robin Radio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
