import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors } from '../constants/theme';
import type { Track } from '../types/catalog';

export function TrackListItem({
  track,
  isCurrent,
  onPress,
}: {
  track: Track;
  isCurrent: boolean;
  onPress: (track: Track) => void;
}) {
  return (
    <Pressable
      style={({ pressed }) => [styles.row, pressed && styles.pressed]}
      onPress={() => onPress(track)}
      accessibilityRole="button"
      accessibilityLabel={`Play ${track.title}`}
      accessibilityState={{ selected: isCurrent }}
    >
      <View style={styles.number}>
        {isCurrent ? (
          <MaterialIcons name="equalizer" size={20} color={colors.primary} />
        ) : (
          <Text style={styles.numberText}>
            {track.trackNumber > 0 ? track.trackNumber : '–'}
          </Text>
        )}
      </View>
      <Text
        style={[styles.title, isCurrent && styles.titleCurrent]}
        numberOfLines={1}
      >
        {track.title}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 16,
    gap: 12,
  },
  pressed: {
    backgroundColor: colors.surfaceHigh,
  },
  number: {
    width: 28,
    alignItems: 'center',
  },
  numberText: {
    color: colors.onSurfaceVariant,
    fontSize: 14,
    fontVariant: ['tabular-nums'],
  },
  title: {
    flex: 1,
    color: colors.onSurface,
    fontSize: 15,
  },
  titleCurrent: {
    color: colors.primary,
    fontWeight: '600',
  },
});
