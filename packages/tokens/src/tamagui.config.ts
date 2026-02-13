import { createTamagui, createTokens } from 'tamagui'
import { createInterFont } from '@tamagui/font-inter'
import { shorthands } from '@tamagui/shorthands'
import { createMedia } from '@tamagui/react-native-media-driver'
import { createAnimations } from '@tamagui/animations-css'

// ============================================================
// DESIGN TOKENS — Single source of truth for web + mobile
// ============================================================

const size = {
  0: 0,
  0.25: 2,
  0.5: 4,
  0.75: 8,
  1: 12,
  1.5: 16,
  2: 20,
  2.5: 24,
  3: 28,
  3.5: 32,
  4: 36,
  true: 16, // default
  5: 44,
  6: 52,
  7: 64,
  8: 80,
  9: 96,
  10: 120,
} as const

const space = {
  0: 0,
  0.5: 2,
  1: 4,
  1.5: 6,
  2: 8,
  2.5: 10,
  3: 12,
  3.5: 14,
  4: 16,
  true: 16,
  5: 20,
  6: 24,
  7: 28,
  8: 32,
  9: 40,
  10: 48,
  11: 56,
  12: 64,
} as const

export const tokens = createTokens({
  color: {
    // Brand
    primary: '#2563EB',
    primaryLight: '#3B82F6',
    primaryDark: '#1D4ED8',
    primaryFaded: '#DBEAFE',

    secondary: '#10B981',
    secondaryLight: '#34D399',
    secondaryDark: '#059669',
    secondaryFaded: '#D1FAE5',

    accent: '#8B5CF6',
    accentLight: '#A78BFA',
    accentDark: '#7C3AED',

    // Semantic
    error: '#EF4444',
    errorLight: '#FCA5A5',
    errorFaded: '#FEE2E2',
    warning: '#F59E0B',
    warningLight: '#FCD34D',
    warningFaded: '#FEF3C7',
    success: '#22C55E',
    successLight: '#86EFAC',
    successFaded: '#DCFCE7',
    info: '#06B6D4',
    infoLight: '#67E8F9',
    infoFaded: '#CFFAFE',

    // Neutrals
    white: '#FFFFFF',
    black: '#000000',
    gray50: '#F8FAFC',
    gray100: '#F1F5F9',
    gray200: '#E2E8F0',
    gray300: '#CBD5E1',
    gray400: '#94A3B8',
    gray500: '#64748B',
    gray600: '#475569',
    gray700: '#334155',
    gray800: '#1E293B',
    gray900: '#0F172A',
    gray950: '#020617',

    // Transparent
    transparent: 'transparent',
  },

  space,
  size,

  radius: {
    0: 0,
    1: 4,
    2: 6,
    3: 8,
    4: 12,
    5: 16,
    6: 20,
    7: 24,
    8: 32,
    true: 8,
    round: 9999,
  },

  zIndex: {
    0: 0,
    1: 100,
    2: 200,
    3: 300,
    4: 400,
    5: 500,
  },
})

// ============================================================
// THEMES
// ============================================================

const lightTheme = {
  background: tokens.color.white,
  backgroundHover: tokens.color.gray50,
  backgroundPress: tokens.color.gray100,
  backgroundFocus: tokens.color.gray50,
  backgroundStrong: tokens.color.gray100,
  backgroundTransparent: tokens.color.transparent,

  color: tokens.color.gray900,
  colorHover: tokens.color.gray800,
  colorPress: tokens.color.gray900,
  colorFocus: tokens.color.gray800,
  colorMuted: tokens.color.gray500,
  colorSubtle: tokens.color.gray400,

  borderColor: tokens.color.gray200,
  borderColorHover: tokens.color.gray300,
  borderColorFocus: tokens.color.primary,
  borderColorPress: tokens.color.gray300,

  placeholderColor: tokens.color.gray400,

  // Semantic surfaces
  surfaceCard: tokens.color.white,
  surfaceOverlay: 'rgba(0, 0, 0, 0.5)',
  surfaceInput: tokens.color.white,

  // Shadows
  shadowColor: 'rgba(0, 0, 0, 0.08)',
  shadowColorHover: 'rgba(0, 0, 0, 0.12)',
}

const darkTheme = {
  background: tokens.color.gray950,
  backgroundHover: tokens.color.gray900,
  backgroundPress: tokens.color.gray800,
  backgroundFocus: tokens.color.gray900,
  backgroundStrong: tokens.color.gray800,
  backgroundTransparent: tokens.color.transparent,

  color: tokens.color.gray50,
  colorHover: tokens.color.white,
  colorPress: tokens.color.gray50,
  colorFocus: tokens.color.white,
  colorMuted: tokens.color.gray400,
  colorSubtle: tokens.color.gray500,

  borderColor: tokens.color.gray800,
  borderColorHover: tokens.color.gray700,
  borderColorFocus: tokens.color.primary,
  borderColorPress: tokens.color.gray700,

  placeholderColor: tokens.color.gray600,

  surfaceCard: tokens.color.gray900,
  surfaceOverlay: 'rgba(0, 0, 0, 0.7)',
  surfaceInput: tokens.color.gray900,

  shadowColor: 'rgba(0, 0, 0, 0.3)',
  shadowColorHover: 'rgba(0, 0, 0, 0.4)',
}

// ============================================================
// FONTS
// ============================================================

const headingFont = createInterFont({
  size: {
    1: 12,
    2: 14,
    3: 16,
    4: 18,
    5: 20,
    6: 24,
    7: 28,
    8: 32,
    9: 40,
    10: 48,
  },
  weight: {
    4: '400',
    5: '500',
    6: '600',
    7: '700',
    8: '800',
  },
  face: {
    600: { normal: 'InterSemiBold' },
    700: { normal: 'InterBold' },
    800: { normal: 'InterExtraBold' },
  },
})

const bodyFont = createInterFont({
  size: {
    1: 12,
    2: 13,
    3: 14,
    4: 15,
    5: 16,
    6: 18,
    7: 20,
    8: 22,
    9: 26,
    10: 30,
  },
  weight: {
    4: '400',
    5: '500',
    6: '600',
  },
  face: {
    400: { normal: 'Inter' },
    500: { normal: 'InterMedium' },
    600: { normal: 'InterSemiBold' },
  },
})

// ============================================================
// ANIMATIONS
// ============================================================

const animations = createAnimations({
  fast: 'ease-in 150ms',
  medium: 'ease-in 300ms',
  slow: 'ease-in 450ms',
  bouncy: 'ease-in 200ms',
  lazy: 'ease-in 600ms',
  quick: 'ease-in 100ms',
  tooltip: 'ease-in 150ms',
})

// ============================================================
// MEDIA QUERIES (responsive breakpoints)
// ============================================================

const media = createMedia({
  xs: { maxWidth: 480 },
  sm: { maxWidth: 640 },
  md: { maxWidth: 768 },
  lg: { maxWidth: 1024 },
  xl: { maxWidth: 1280 },
  xxl: { maxWidth: 1536 },
  gtXs: { minWidth: 481 },
  gtSm: { minWidth: 641 },
  gtMd: { minWidth: 769 },
  gtLg: { minWidth: 1025 },
  gtXl: { minWidth: 1281 },
  short: { maxHeight: 820 },
  tall: { minHeight: 820 },
  hoverNone: { hover: 'none' },
  pointerCoarse: { pointer: 'coarse' },
})

// ============================================================
// CREATE CONFIG — export for TamaguiProvider in web + mobile
// ============================================================

const config = createTamagui({
  tokens,
  themes: {
    light: lightTheme,
    dark: darkTheme,
  },
  fonts: {
    heading: headingFont,
    body: bodyFont,
  },
  animations,
  media,
  shorthands,
  defaultTheme: 'light',
  shouldAddPrefersColorThemes: true,
  themeClassNameOnRoot: true,
})

export default config

// Type export for strong typing across the monorepo
export type AppConfig = typeof config

declare module 'tamagui' {
  interface TamaguiCustomConfig extends AppConfig {}
}
