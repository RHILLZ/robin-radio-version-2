import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for connectivity detection
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Convenience provider for simple online/offline check
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);

  return connectivityAsync.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true, // Assume online while loading
    error: (_, __) => true, // Assume online on error
  );
});
