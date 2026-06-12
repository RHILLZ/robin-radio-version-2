import { DarkTheme, Stack, ThemeProvider } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import TrackPlayer from 'react-native-track-player';

import { colors } from '../constants/theme';
import { initAudioCache } from '../lib/cache/audioCache';
import { playbackService } from '../lib/player/service';
import { ensurePlayerSetup } from '../lib/player/setup';
import { useCatalogStore } from '../stores/catalogStore';

// Must be registered outside any component so the service survives
// the app being backgrounded.
TrackPlayer.registerPlaybackService(() => playbackService);

const theme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    background: colors.background,
    card: colors.surface,
    text: colors.onSurface,
    primary: colors.primary,
    border: colors.outline,
  },
};

export default function RootLayout() {
  useEffect(() => {
    initAudioCache();
    void ensurePlayerSetup();
    void useCatalogStore.getState().load();
  }, []);

  return (
    <ThemeProvider value={theme}>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: colors.background },
        }}
      >
        <Stack.Screen name="index" />
        <Stack.Screen name="album/[id]" />
        <Stack.Screen name="search" />
        <Stack.Screen name="player" options={{ presentation: 'modal' }} />
      </Stack>
    </ThemeProvider>
  );
}
