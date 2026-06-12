import { create } from 'zustand';

/**
 * Small UI-side player state. Everything about playback itself (current
 * track, position, play state) comes straight from react-native-track-player
 * hooks; this store only tracks what the native player can't know.
 */
interface PlayerUiState {
  /** True while the queue was started via the Radio button. */
  radioActive: boolean;
  setRadioActive: (active: boolean) => void;
}

export const usePlayerStore = create<PlayerUiState>((set) => ({
  radioActive: false,
  setRadioActive: (active) => set({ radioActive: active }),
}));
