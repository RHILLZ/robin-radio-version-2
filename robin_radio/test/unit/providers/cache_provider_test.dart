import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/providers/cache_provider.dart';

void main() {
  group('CacheProvider', () {
    test('cacheServiceProvider provides CacheService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cacheService = container.read(cacheServiceProvider);

      expect(cacheService, isNotNull);
    });
  });
}
