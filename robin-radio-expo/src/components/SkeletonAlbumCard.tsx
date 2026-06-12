import { useEffect, useRef } from 'react';
import { Animated, StyleSheet, View } from 'react-native';

import { colors, radii, spacing } from '../constants/theme';

/**
 * Loading placeholder for an album card. Uses the design docs' pulse
 * variant (opacity 0.7→1.0, 1500ms loop).
 */
export function SkeletonAlbumCard() {
  const pulse = useRef(new Animated.Value(0.7)).current;

  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1, duration: 750, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 0.7, duration: 750, useNativeDriver: true }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [pulse]);

  return (
    <Animated.View style={[styles.card, { opacity: pulse }]}>
      <View style={styles.cover} />
      <View style={styles.title} />
      <View style={styles.artist} />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
  },
  cover: {
    aspectRatio: 1,
    borderRadius: radii.cover,
    backgroundColor: colors.surfaceHigh,
  },
  title: {
    height: 14,
    width: '70%',
    borderRadius: radii.skeletonLine,
    backgroundColor: colors.surfaceHigh,
    marginTop: spacing.cardGap,
  },
  artist: {
    height: 12,
    width: '50%',
    borderRadius: radii.skeletonLine,
    backgroundColor: colors.surfaceHigh,
    marginTop: spacing.cardGap,
  },
});
