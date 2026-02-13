export { default as config, tokens } from './tamagui.config'
export type { AppConfig } from './tamagui.config'

// Re-export brand constants for use in non-Tamagui contexts (e.g., API email templates)
export const brandColors = {
  primary: '#2563EB',
  primaryDark: '#1D4ED8',
  secondary: '#10B981',
  error: '#EF4444',
  warning: '#F59E0B',
  success: '#22C55E',
} as const

export const brandFonts = {
  heading: 'Inter',
  body: 'Inter',
} as const
