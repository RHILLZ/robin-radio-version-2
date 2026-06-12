import Slider from '@react-native-community/slider';
import { MaterialIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import TrackPlayer, {
  State,
  useActiveTrack,
  usePlaybackState,
  useProgress,
} from 'react-native-track-player';

import { AlbumCover } from '../components/AlbumCover';
import { colors, radii, spacing } from '../constants/theme';
import { formatTime } from '../lib/format';
import { skipNext, skipPrevious, togglePlayPause } from '../lib/player/playback';

export default function PlayerScreen() {
  const router = useRouter();
  const track = useActiveTrack();
  const { state } = usePlaybackState();
  const { position, duration } = useProgress();

  const isPlaying = state === State.Playing;
  const isLoading = state === State.Loading || state === State.Buffering;

  return (
    <SafeAreaView style={styles.screen} edges={['top', 'bottom']}>
      <View style={styles.header}>
        <Pressable
          onPress={router.back}
          hitSlop={8}
          accessibilityRole="button"
          accessibilityLabel="Close player"
        >
          <MaterialIcons name="keyboard-arrow-down" size={32} color={colors.onSurface} />
        </Pressable>
      </View>

      <View style={styles.artWrap}>
        <View style={styles.art}>
          <AlbumCover
            uri={track?.artwork as string | undefined}
            borderRadius={radii.playerArt}
            iconSize={96}
          />
        </View>
      </View>

      <View style={styles.info}>
        <Text style={styles.title} numberOfLines={2}>
          {track?.title ?? 'Nothing playing'}
        </Text>
        <Text style={styles.subtitle} numberOfLines={1}>
          {track ? `${track.artist ?? ''}${track.album ? ` • ${track.album}` : ''}` : ''}
        </Text>
      </View>

      <View style={styles.progress}>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={duration > 0 ? duration : 1}
          value={Math.min(position, duration > 0 ? duration : 1)}
          onSlidingComplete={(value) => TrackPlayer.seekTo(value)}
          minimumTrackTintColor={colors.primary}
          maximumTrackTintColor={colors.outline}
          thumbTintColor={colors.primary}
          disabled={!track}
          accessibilityLabel="Seek"
        />
        <View style={styles.times}>
          <Text style={styles.time}>{formatTime(position)}</Text>
          <Text style={styles.time}>{duration > 0 ? formatTime(duration) : '--:--'}</Text>
        </View>
      </View>

      <View style={styles.controls}>
        <Pressable
          onPress={skipPrevious}
          hitSlop={12}
          accessibilityRole="button"
          accessibilityLabel="Previous track"
        >
          <MaterialIcons name="skip-previous" size={48} color={colors.onSurface} />
        </Pressable>
        <Pressable
          onPress={togglePlayPause}
          style={styles.playButton}
          accessibilityRole="button"
          accessibilityLabel={isPlaying ? 'Pause' : 'Play'}
        >
          {isLoading ? (
            <ActivityIndicator size="large" color={colors.onPrimary} />
          ) : (
            <MaterialIcons
              name={isPlaying ? 'pause' : 'play-arrow'}
              size={48}
              color={colors.onPrimary}
            />
          )}
        </Pressable>
        <Pressable
          onPress={skipNext}
          hitSlop={12}
          accessibilityRole="button"
          accessibilityLabel="Next track"
        >
          <MaterialIcons name="skip-next" size={48} color={colors.onSurface} />
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
    paddingHorizontal: spacing.screen,
  },
  header: {
    alignItems: 'flex-start',
    paddingVertical: 8,
  },
  artWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  art: {
    width: '90%',
    maxWidth: 350,
    aspectRatio: 1,
    borderRadius: radii.playerArt,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.4,
    shadowRadius: 20,
    elevation: 16,
  },
  info: {
    alignItems: 'center',
    gap: 6,
    paddingVertical: 16,
  },
  title: {
    color: colors.onSurface,
    fontSize: 22,
    fontWeight: '700',
    textAlign: 'center',
  },
  subtitle: {
    color: colors.onSurfaceVariant,
    fontSize: 14,
  },
  progress: {
    paddingVertical: 4,
  },
  slider: {
    width: '100%',
    height: 36,
  },
  times: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 4,
  },
  time: {
    color: colors.onSurfaceVariant,
    fontSize: 12,
    fontVariant: ['tabular-nums'],
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 32,
    paddingVertical: 24,
  },
  playButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
