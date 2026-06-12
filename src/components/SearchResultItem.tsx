import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, radii } from '../constants/theme';
import type { SearchResult } from '../types/catalog';
import { AlbumCover } from './AlbumCover';

const TYPE_ICONS = {
  artist: 'person',
  album: 'album',
  track: 'music-note',
} as const;

export function SearchResultItem({
  result,
  onPress,
}: {
  result: SearchResult;
  onPress: (result: SearchResult) => void;
}) {
  return (
    <Pressable
      style={({ pressed }) => [styles.row, pressed && styles.pressed]}
      onPress={() => onPress(result)}
      accessibilityRole="button"
      accessibilityLabel={`${result.type}: ${result.title}, ${result.subtitle}`}
    >
      <View style={styles.art}>
        {result.coverUrl ? (
          <AlbumCover uri={result.coverUrl} borderRadius={radii.miniArt} iconSize={20} />
        ) : (
          <View style={styles.iconFallback}>
            <MaterialIcons
              name={TYPE_ICONS[result.type]}
              size={22}
              color={colors.onSurfaceVariant}
            />
          </View>
        )}
      </View>
      <View style={styles.info}>
        <Text style={styles.title} numberOfLines={1}>
          {result.title}
        </Text>
        <Text style={styles.subtitle} numberOfLines={1}>
          {result.subtitle}
        </Text>
      </View>
      <MaterialIcons name="chevron-right" size={22} color={colors.onSurfaceVariant} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  pressed: {
    backgroundColor: colors.surfaceHigh,
  },
  art: {
    width: 44,
    height: 44,
    borderRadius: radii.miniArt,
    overflow: 'hidden',
  },
  iconFallback: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.surfaceHigh,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radii.miniArt,
  },
  info: {
    flex: 1,
  },
  title: {
    color: colors.onSurface,
    fontSize: 15,
    fontWeight: '500',
  },
  subtitle: {
    color: colors.onSurfaceVariant,
    fontSize: 12,
    marginTop: 2,
  },
});
