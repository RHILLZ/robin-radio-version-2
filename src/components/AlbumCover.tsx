import { MaterialIcons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { StyleSheet, View } from 'react-native';

import { colors } from '../constants/theme';

/**
 * Album artwork with a music-note fallback when there is no cover.
 * expo-image gives memory+disk caching out of the box.
 */
export function AlbumCover({
  uri,
  borderRadius,
  iconSize = 48,
}: {
  uri: string | null | undefined;
  borderRadius: number;
  iconSize?: number;
}) {
  if (!uri) {
    return (
      <View style={[styles.fallback, { borderRadius }]}>
        <MaterialIcons name="music-note" size={iconSize} color={colors.onSurfaceVariant} />
      </View>
    );
  }
  return (
    <Image
      source={{ uri }}
      style={[styles.image, { borderRadius }]}
      contentFit="cover"
      transition={200}
    />
  );
}

const styles = StyleSheet.create({
  image: {
    width: '100%',
    height: '100%',
  },
  fallback: {
    width: '100%',
    height: '100%',
    backgroundColor: colors.surfaceHigh,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
