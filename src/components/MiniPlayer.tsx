import { MaterialIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import {
  State,
  useActiveTrack,
  usePlaybackState,
  useProgress,
} from 'react-native-track-player';

import { colors, radii } from '../constants/theme';
import { skipNext, togglePlayPause } from '../lib/player/playback';
import { AlbumCover } from './AlbumCover';

/**
 * Persistent bottom bar showing the current track. Hidden when nothing is
 * queued; tapping it opens the full player.
 */
export function MiniPlayer() {
  const router = useRouter();
  const track = useActiveTrack();
  const { state } = usePlaybackState();
  const { position, duration } = useProgress();

  if (!track) return null;

  const isPlaying = state === State.Playing;
  const isLoading = state === State.Loading || state === State.Buffering;
  const progress = duration > 0 ? Math.min(1, position / duration) : 0;

  return (
    <View style={styles.container}>
      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
      </View>
      <Pressable
        style={styles.row}
        onPress={() => router.push('/player')}
        accessibilityRole="button"
        accessibilityLabel={`Now playing: ${track.title ?? 'unknown'}. Open player.`}
      >
        <View style={styles.art}>
          <AlbumCover uri={track.artwork as string | undefined} borderRadius={radii.miniArt} iconSize={24} />
        </View>
        <View style={styles.info}>
          <Text style={styles.title} numberOfLines={1}>
            {track.title}
          </Text>
          <Text style={styles.artist} numberOfLines={1}>
            {track.artist}
          </Text>
        </View>
        <Pressable
          onPress={togglePlayPause}
          hitSlop={8}
          accessibilityRole="button"
          accessibilityLabel={isPlaying ? 'Pause' : 'Play'}
        >
          {isLoading ? (
            <ActivityIndicator color={colors.onSurface} />
          ) : (
            <MaterialIcons
              name={isPlaying ? 'pause' : 'play-arrow'}
              size={32}
              color={colors.onSurface}
            />
          )}
        </Pressable>
        <Pressable
          onPress={skipNext}
          hitSlop={8}
          accessibilityRole="button"
          accessibilityLabel="Next track"
        >
          <MaterialIcons name="skip-next" size={32} color={colors.onSurface} />
        </Pressable>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.surfaceHigh,
  },
  progressTrack: {
    height: 2,
    backgroundColor: colors.outline,
  },
  progressFill: {
    height: 2,
    backgroundColor: colors.primary,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  art: {
    width: 48,
    height: 48,
    borderRadius: radii.miniArt,
    overflow: 'hidden',
  },
  info: {
    flex: 1,
  },
  title: {
    color: colors.onSurface,
    fontSize: 14,
    fontWeight: '600',
  },
  artist: {
    color: colors.onSurfaceVariant,
    fontSize: 12,
  },
});
