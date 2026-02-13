'use client'

import type { ReactNode } from 'react'
import { useServerInsertedHTML } from 'next/navigation'
import { TamaguiProvider } from 'tamagui'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import config from '../tamagui.config'

// React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute
      retry: 1,
    },
  },
})

export function NextTamaguiProvider({ children }: { children: ReactNode }) {
  // Inject Tamagui CSS into the <head> on the server
  useServerInsertedHTML(() => {
    // @ts-ignore — getNewCSS is available on the config
    const newCSS = config.getNewCSS?.()
    if (newCSS) {
      return <style dangerouslySetInnerHTML={{ __html: newCSS }} />
    }
    return null
  })

  return (
    <QueryClientProvider client={queryClient}>
      <TamaguiProvider config={config} defaultTheme="light">
        {children}
      </TamaguiProvider>
    </QueryClientProvider>
  )
}
