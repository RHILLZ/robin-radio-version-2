/**
 * Dark theme tokens ported from the Flutter app's Material 3 dark scheme
 * (seeded from deep purple) and the design-documentation specs.
 */
export const colors = {
  background: '#141218',
  surface: '#1D1B20',
  surfaceHigh: '#2D2D3A',
  surfaceHighest: '#35354A',
  onSurface: '#E6E0E9',
  onSurfaceVariant: '#AEA9B4',
  outline: '#49454F',
  primary: '#D0BCFF',
  onPrimary: '#381E72',
  error: '#F2B8B5',
  // Radio button (from widgets/radio_button.dart)
  radioActive: '#FF0083',
  radioActiveBg: '#3A1A2A',
  radioInactiveBg: '#2A2A2A',
  radioInactiveIcon: '#666666',
  // Offline banner
  offlineBanner: '#B96A00',
} as const;

export const spacing = {
  /** Album grid padding and gutters (design docs: 16px everywhere). */
  grid: 16,
  /** Gap between card elements (cover→title, title→artist). */
  cardGap: 4,
  screen: 16,
} as const;

export const radii = {
  cover: 8,
  playerArt: 12,
  miniArt: 6,
  skeletonLine: 4,
} as const;

/** Responsive album grid columns (design docs breakpoints). */
export function gridColumns(width: number): number {
  if (width < 400) return 2;
  if (width < 600) return 3;
  if (width < 900) return 4;
  return 5;
}

/** Skeleton card count per breakpoint (design docs). */
export function skeletonCount(width: number): number {
  return width < 600 ? 6 : 8;
}
