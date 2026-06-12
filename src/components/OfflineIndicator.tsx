import { MaterialIcons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../constants/theme';
import { useIsOnline } from '../hooks/useIsOnline';

export function OfflineIndicator() {
  const isOnline = useIsOnline();
  if (isOnline) return null;

  return (
    <View
      style={styles.banner}
      accessibilityLiveRegion="polite"
      accessibilityLabel="Offline mode"
    >
      <MaterialIcons name="cloud-off" size={16} color={colors.onSurface} />
      <Text style={styles.text}>Offline Mode</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: colors.offlineBanner,
    paddingVertical: 6,
  },
  text: {
    color: colors.onSurface,
    fontSize: 13,
    fontWeight: '600',
  },
});
