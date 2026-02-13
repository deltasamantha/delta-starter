import { withTamagui } from '@tamagui/next-plugin'

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Next.js 16: React Compiler is stable
  reactCompiler: true,

  // Transpile monorepo packages
  transpilePackages: [
    '__SCOPE__/ui',
    '__SCOPE__/tokens',
    '__SCOPE__/shared',
    '__SCOPE__/business-logic',
    '__SCOPE__/api-client',
    'tamagui',
    '@tamagui/core',
    '@tamagui/font-inter',
    'react-native-web',
  ],

  // Turbopack config (default in v16)
  turbopack: {
    resolveAlias: {
      'react-native': 'react-native-web',
    },
  },
}

// Tamagui plugin (optional but recommended for optimization)
export default withTamagui({
  config: './tamagui.config.ts',
  components: ['tamagui', '__SCOPE__/ui'],
  appDir: true,
})(nextConfig)
