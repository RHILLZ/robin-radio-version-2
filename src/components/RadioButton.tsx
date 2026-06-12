import { MaterialIcons } from '@expo/vector-icons';
import { ActivityIndicator, Pressable, StyleSheet } from 'react-native';

import { colors } from '../constants/theme';

const BUTTON_SIZE = 80;
const ICON_SIZE = 40;

/**
 * The big circular radio toggle (ported from widgets/radio_button.dart):
 * dark gray when off, pink glow when on.
 */
export function RadioButton({
  active,
  loading,
  onPress,
}: {
  active: boolean;
  loading?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={loading}
      accessibilityRole="button"
      accessibilityState={{ selected: active, busy: loading }}
      accessibilityLabel={active ? 'Turn radio off' : 'Turn radio on'}
      style={({ pressed }) => [
        styles.button,
        active ? styles.buttonActive : styles.buttonInactive,
        pressed && styles.pressed,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={colors.radioActive} />
      ) : (
        <MaterialIcons
          name="power-settings-new"
          size={ICON_SIZE}
          color={active ? colors.radioActive : colors.radioInactiveIcon}
        />
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    width: BUTTON_SIZE,
    height: BUTTON_SIZE,
    borderRadius: BUTTON_SIZE / 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonInactive: {
    backgroundColor: colors.radioInactiveBg,
  },
  buttonActive: {
    backgroundColor: colors.radioActiveBg,
    shadowColor: colors.radioActive,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.6,
    shadowRadius: 16,
    elevation: 12,
  },
  pressed: {
    transform: [{ scale: 0.95 }],
  },
});
