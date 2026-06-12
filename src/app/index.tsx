import { MaterialIcons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import {
  FlatList,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AlbumGrid } from '../components/AlbumGrid';
import { MiniPlayer } from '../components/MiniPlayer';
import { OfflineIndicator } from '../components/OfflineIndicator';
import { RadioButton } from '../components/RadioButton';
import { SkeletonAlbumCard } from '../components/SkeletonAlbumCard';
import { colors, gridColumns, skeletonCount, spacing } from '../constants/theme';
import { playShuffled, stopPlayback } from '../lib/player/playback';
import { useCatalogStore } from '../stores/catalogStore';
import { usePlayerStore } from '../stores/playerStore';
import type { Album } from '../types/catalog';

export default function HomeScreen() {
  const router = useRouter();
  const { width } = useWindowDimensions();
  const { albums, tracks, isLoading, isComplete, error, refresh } = useCatalogStore();
  const radioActive = usePlayerStore((s) => s.radioActive);
  const [radioBusy, setRadioBusy] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const onAlbumPress = (album: Album) => {
    router.push({ pathname: '/album/[id]', params: { id: album.id } });
  };

  const onRadioPress = async () => {
    setRadioBusy(true);
    try {
      if (radioActive) {
        await stopPlayback();
      } else {
        await playShuffled(tracks);
      }
    } finally {
      setRadioBusy(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refresh();
    } finally {
      setRefreshing(false);
    }
  };

  const statusLine = isComplete
    ? `${tracks.length} songs • ${albums.length} albums`
    : albums.length > 0
      ? `${albums.length} albums found...`
      : 'Loading your music...';

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.header}>
        <Image
          source={require('../../assets/images/branding/logo_icon.png')}
          style={styles.logo}
          contentFit="contain"
        />
        <Text style={styles.headerTitle}>Robin Radio</Text>
        <Pressable
          onPress={() => router.push('/search')}
          hitSlop={8}
          accessibilityRole="button"
          accessibilityLabel="Search"
        >
          <MaterialIcons name="search" size={28} color={colors.onSurface} />
        </Pressable>
      </View>

      <OfflineIndicator />

      <View style={styles.radioSection}>
        <Text style={styles.statusLine}>{statusLine}</Text>
        <RadioButton active={radioActive} loading={radioBusy} onPress={onRadioPress} />
      </View>

      <View style={styles.content}>
        {error ? (
          <View style={styles.centered}>
            <MaterialIcons name="error-outline" size={48} color={colors.error} />
            <Text style={styles.message}>{error}</Text>
            <Pressable style={styles.retryButton} onPress={refresh} accessibilityRole="button">
              <Text style={styles.retryText}>Try Again</Text>
            </Pressable>
          </View>
        ) : albums.length === 0 && (isLoading || !isComplete) ? (
          <FlatList
            data={Array.from({ length: skeletonCount(width) }, (_, i) => i)}
            key={`skeleton-${gridColumns(width)}`}
            numColumns={gridColumns(width)}
            keyExtractor={(i) => `skeleton-${i}`}
            renderItem={() => <SkeletonAlbumCard />}
            columnWrapperStyle={{ gap: spacing.grid }}
            contentContainerStyle={styles.skeletonGrid}
            accessibilityLabel="Loading albums, please wait"
            scrollEnabled={false}
          />
        ) : albums.length === 0 ? (
          <View style={styles.centered}>
            <MaterialIcons name="library-music" size={48} color={colors.onSurfaceVariant} />
            <Text style={styles.message}>No music found</Text>
          </View>
        ) : (
          <AlbumGrid
            albums={albums}
            onAlbumPress={onAlbumPress}
            refreshControl={
              <RefreshControl
                refreshing={refreshing}
                onRefresh={onRefresh}
                tintColor={colors.primary}
              />
            }
          />
        )}
      </View>

      <MiniPlayer />
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
    paddingHorizontal: spacing.screen,
    paddingVertical: 8,
    gap: 12,
  },
  logo: {
    width: 36,
    height: 36,
  },
  headerTitle: {
    flex: 1,
    color: colors.onSurface,
    fontSize: 20,
    fontWeight: '700',
  },
  radioSection: {
    alignItems: 'center',
    paddingVertical: 12,
    gap: 12,
  },
  statusLine: {
    color: colors.onSurfaceVariant,
    fontSize: 13,
  },
  content: {
    flex: 1,
  },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    padding: 32,
  },
  message: {
    color: colors.onSurfaceVariant,
    fontSize: 15,
    textAlign: 'center',
  },
  retryButton: {
    backgroundColor: colors.primary,
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 24,
  },
  retryText: {
    color: colors.onPrimary,
    fontWeight: '600',
  },
  skeletonGrid: {
    padding: spacing.grid,
    gap: spacing.grid,
  },
});
