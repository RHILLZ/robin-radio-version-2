import { MaterialIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useMemo, useState } from 'react';
import {
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { SearchResultItem } from '../components/SearchResultItem';
import { colors, spacing } from '../constants/theme';
import { useDebouncedValue } from '../hooks/useDebouncedValue';
import { playTrack } from '../lib/player/playback';
import { searchCatalog } from '../lib/search/searchService';
import { useCatalogStore } from '../stores/catalogStore';
import type { SearchResult } from '../types/catalog';

export default function SearchScreen() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  // Debounced (250ms) so we don't re-rank the catalog on every keystroke.
  const debouncedQuery = useDebouncedValue(query, 250);
  const { artists, albums, tracks, albumsForArtist } = useCatalogStore();

  const results = useMemo(
    () => searchCatalog({ artists, albums, tracks }, debouncedQuery),
    [artists, albums, tracks, debouncedQuery],
  );

  const onResultPress = (result: SearchResult) => {
    switch (result.type) {
      case 'artist': {
        const artistAlbums = albumsForArtist(result.artist!.id);
        if (artistAlbums.length > 0) {
          router.push({ pathname: '/album/[id]', params: { id: artistAlbums[0].id } });
        }
        break;
      }
      case 'album':
        router.push({ pathname: '/album/[id]', params: { id: result.album!.id } });
        break;
      case 'track':
        void playTrack(result.track!);
        router.push('/player');
        break;
    }
  };

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.header}>
        <Pressable onPress={router.back} hitSlop={8} accessibilityRole="button" accessibilityLabel="Back">
          <MaterialIcons name="arrow-back" size={26} color={colors.onSurface} />
        </Pressable>
        <View style={styles.inputWrap}>
          <MaterialIcons name="search" size={20} color={colors.onSurfaceVariant} />
          <TextInput
            style={styles.input}
            value={query}
            onChangeText={setQuery}
            placeholder="Search songs, albums, artists"
            placeholderTextColor={colors.onSurfaceVariant}
            autoFocus
            autoCorrect={false}
            returnKeyType="search"
            accessibilityLabel="Search input"
          />
          {query.length > 0 && (
            <Pressable onPress={() => setQuery('')} hitSlop={8} accessibilityRole="button" accessibilityLabel="Clear search">
              <MaterialIcons name="close" size={20} color={colors.onSurfaceVariant} />
            </Pressable>
          )}
        </View>
      </View>

      {debouncedQuery.trim().length === 0 ? (
        <View style={styles.centered}>
          <MaterialIcons name="search" size={48} color={colors.onSurfaceVariant} />
          <Text style={styles.title}>Search for music</Text>
          <Text style={styles.message}>Find songs, albums, or artists</Text>
        </View>
      ) : results.length === 0 ? (
        <View style={styles.centered}>
          <MaterialIcons name="search-off" size={48} color={colors.onSurfaceVariant} />
          <Text style={styles.title}>No results found</Text>
          <Text style={styles.message}>Try a different search term</Text>
        </View>
      ) : (
        <FlatList
          data={results}
          keyExtractor={(result) => `${result.type}-${result.title}-${result.subtitle}`}
          keyboardShouldPersistTaps="handled"
          ListHeaderComponent={
            <Text style={styles.count}>
              {results.length} result{results.length === 1 ? '' : 's'}
            </Text>
          }
          renderItem={({ item }) => (
            <SearchResultItem result={item} onPress={onResultPress} />
          )}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: spacing.screen,
    paddingVertical: 10,
  },
  inputWrap: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: colors.surfaceHigh,
    borderRadius: 24,
    paddingHorizontal: 14,
    paddingVertical: 4,
  },
  input: {
    flex: 1,
    color: colors.onSurface,
    fontSize: 15,
    paddingVertical: 8,
  },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 32,
  },
  title: {
    color: colors.onSurface,
    fontSize: 17,
    fontWeight: '600',
  },
  message: {
    color: colors.onSurfaceVariant,
    fontSize: 14,
  },
  count: {
    color: colors.onSurfaceVariant,
    fontSize: 13,
    paddingHorizontal: spacing.screen,
    paddingVertical: 8,
  },
});
