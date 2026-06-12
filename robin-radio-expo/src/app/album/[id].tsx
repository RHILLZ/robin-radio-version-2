import { MaterialIcons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useActiveTrack } from 'react-native-track-player';

import { AlbumCover } from '../../components/AlbumCover';
import { MiniPlayer } from '../../components/MiniPlayer';
import { TrackListItem } from '../../components/TrackListItem';
import { colors, radii, spacing } from '../../constants/theme';
import { playAlbum } from '../../lib/player/playback';
import { useCatalogStore } from '../../stores/catalogStore';
import type { Track } from '../../types/catalog';

export default function AlbumScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const album = useCatalogStore((s) => s.albums.find((a) => a.id === id));
  const tracks = useCatalogStore((s) => s.tracksForAlbum(id ?? ''));
  const activeTrack = useActiveTrack();

  const onTrackPress = (track: Track) => {
    const index = tracks.findIndex((t) => t.id === track.id);
    void playAlbum(tracks, Math.max(0, index));
  };

  if (!album) {
    return (
      <SafeAreaView style={styles.screen}>
        <Header onBack={router.back} title="Album" />
        <View style={styles.centered}>
          <Text style={styles.message}>Album not found</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <Header onBack={router.back} title={album.title} />
      <FlatList
        data={tracks}
        keyExtractor={(track) => track.id}
        renderItem={({ item }) => (
          <TrackListItem
            track={item}
            isCurrent={activeTrack?.id === item.id}
            onPress={onTrackPress}
          />
        )}
        ListHeaderComponent={
          <View style={styles.albumHeader}>
            <View style={styles.cover}>
              <AlbumCover uri={album.coverUrl} borderRadius={radii.playerArt} iconSize={64} />
            </View>
            <Text style={styles.albumTitle}>{album.title}</Text>
            <Text style={styles.albumMeta}>
              {album.artistName} • {tracks.length} track{tracks.length === 1 ? '' : 's'}
            </Text>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.centered}>
            <Text style={styles.message}>No tracks</Text>
          </View>
        }
      />
      <MiniPlayer />
    </SafeAreaView>
  );
}

function Header({ onBack, title }: { onBack: () => void; title: string }) {
  return (
    <View style={styles.navHeader}>
      <Pressable onPress={onBack} hitSlop={8} accessibilityRole="button" accessibilityLabel="Back">
        <MaterialIcons name="arrow-back" size={26} color={colors.onSurface} />
      </Pressable>
      <Text style={styles.navTitle} numberOfLines={1}>
        {title}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  navHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    paddingHorizontal: spacing.screen,
    paddingVertical: 10,
  },
  navTitle: {
    flex: 1,
    color: colors.onSurface,
    fontSize: 17,
    fontWeight: '600',
  },
  albumHeader: {
    alignItems: 'center',
    padding: spacing.screen,
    gap: 8,
  },
  cover: {
    width: 240,
    height: 240,
    borderRadius: radii.playerArt,
    overflow: 'hidden',
  },
  albumTitle: {
    color: colors.onSurface,
    fontSize: 20,
    fontWeight: '700',
    textAlign: 'center',
    marginTop: 8,
  },
  albumMeta: {
    color: colors.onSurfaceVariant,
    fontSize: 13,
  },
  centered: {
    alignItems: 'center',
    padding: 48,
  },
  message: {
    color: colors.onSurfaceVariant,
    fontSize: 15,
  },
});
