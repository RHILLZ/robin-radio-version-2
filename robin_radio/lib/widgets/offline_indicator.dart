import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';

/// A banner that displays when the app is offline
///
/// Shows a subtle indicator at the top of the screen when there's no
/// network connectivity. Hidden when online.
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      label: 'You are currently offline. Cached music is still available.',
      child: Container(
        width: double.infinity,
        color: Colors.orange.shade800,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Offline Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
