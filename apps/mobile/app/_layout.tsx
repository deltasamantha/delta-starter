import { useEffect } from 'react'
import { Stack } from 'expo-router'
import { TamaguiProvider, Theme } from 'tamagui'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useColorScheme } from 'react-native'
import config from '__SCOPE__/tokens/tamagui.config'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,
      retry: 1,
    },
  },
})

export default function RootLayout() {
  const colorScheme = useColorScheme()

  return (
    <QueryClientProvider client={queryClient}>
      <TamaguiProvider config={config} defaultTheme={colorScheme || 'light'}>
        <Theme name={colorScheme || 'light'}>
          <Stack
            screenOptions={{
              headerShown: false,
            }}
          />
        </Theme>
      </TamaguiProvider>
    </QueryClientProvider>
  )
}
