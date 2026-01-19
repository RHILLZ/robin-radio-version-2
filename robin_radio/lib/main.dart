import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: RobinRadioApp()));
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
      home: const PlaceholderHomeScreen(),
    );
  }
}

/// Placeholder home screen until US1 implementation
class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Robin Radio'),
        centerTitle: true,
      ),
      body: Center(
        child: catalogState.isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading catalog...'),
                ],
              )
            : catalogState.error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        catalogState.error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(catalogProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.library_music,
                        size: 64,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${catalogState.artists.length} Artists',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${catalogState.albums.length} Albums',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${catalogState.tracks.length} Tracks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Radio button coming in Phase 3 (US1)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
      ),
    );
  }
}
