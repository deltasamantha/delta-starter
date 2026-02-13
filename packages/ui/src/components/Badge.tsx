'use client'

import { styled, SizableText, XStack } from 'tamagui'
import type { ReactNode } from 'react'

const BadgeFrame = styled(XStack, {
  paddingHorizontal: '$2',
  paddingVertical: '$0.5',
  borderRadius: '$round',
  alignItems: 'center',
  justifyContent: 'center',

  variants: {
    variant: {
      primary: { backgroundColor: '$primaryFaded' },
      secondary: { backgroundColor: '$secondaryFaded' },
      success: { backgroundColor: '$successFaded' },
      error: { backgroundColor: '$errorFaded' },
      warning: { backgroundColor: '$warningFaded' },
      info: { backgroundColor: '$infoFaded' },
      neutral: { backgroundColor: '$backgroundStrong' },
    },
  } as const,

  defaultVariants: {
    variant: 'neutral',
  },
})

const textColors = {
  primary: '$primaryDark',
  secondary: '$secondaryDark',
  success: '$success',
  error: '$error',
  warning: '$warning',
  info: '$info',
  neutral: '$colorMuted',
} as const

interface BadgeProps {
  variant?: keyof typeof textColors
  children: ReactNode
}

export function Badge({ variant = 'neutral', children }: BadgeProps) {
  return (
    <BadgeFrame variant={variant}>
      <SizableText size="$1" fontWeight="600" color={textColors[variant]}>
        {children}
      </SizableText>
    </BadgeFrame>
  )
}
