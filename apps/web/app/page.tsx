import { H1, Paragraph, YStack, Button } from '__SCOPE__/ui'
import { APP_NAME } from '__SCOPE__/shared'
import Link from 'next/link'

export default function HomePage() {
  return (
    <YStack flex={1} justifyContent="center" alignItems="center" padding="$6" gap="$4">
      <H1 textAlign="center">{APP_NAME}</H1>
      <Paragraph size="$5" color="$colorMuted" textAlign="center" maxWidth={600}>
        Connect with qualified workers instantly. Post jobs, manage shifts, and handle payments — all
        in one platform.
      </Paragraph>

      <YStack gap="$3" width="100%" maxWidth={320} marginTop="$4">
        <Link href="/login">
          <Button size="$5" theme="active" width="100%">
            Sign In
          </Button>
        </Link>
        <Link href="/register">
          <Button size="$5" variant="outlined" width="100%">
            Create Account
          </Button>
        </Link>
      </YStack>
    </YStack>
  )
}
