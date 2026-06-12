import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, radii, spacing } from '../constants/theme';
import type { Album } from '../types/catalog';
import { AlbumCover } from './AlbumCover';

export function AlbumCard({
  album,
  onPress,
}: {
  album: Album;
  onPress: (album: Album) => void;
}) {
  return (
    <Pressable
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}
      onPress={() => onPress(album)}
      accessibilityRole="button"
      accessibilityLabel={`${album.title} by ${album.artistName}`}
    >
      <View style={styles.cover}>
        <AlbumCover uri={album.coverUrl} borderRadius={radii.cover} />
      </View>
      <Text style={styles.title} numberOfLines={1}>
        {album.title}
      </Text>
      <Text style={styles.artist} numberOfLines={1}>
        {album.artistName}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
  },
  pressed: {
    opacity: 0.7,
  },
  cover: {
    aspectRatio: 1,
    borderRadius: radii.cover,
    overflow: 'hidden',
  },
  title: {
    color: colors.onSurface,
    fontSize: 14,
    fontWeight: '600',
    marginTop: spacing.cardGap,
  },
  artist: {
    color: colors.onSurfaceVariant,
    fontSize: 12,
    marginTop: spacing.cardGap,
  },
});
