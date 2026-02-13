import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

/**
 * Next.js 16: proxy.ts replaces middleware.ts
 * Runs on Node.js runtime (not Edge).
 */
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Redirect authenticated users away from auth pages
  const token = request.cookies.get('access_token')?.value
  const isAuthPage = pathname.startsWith('/login') || pathname.startsWith('/register')
  const isDashboardPage = pathname.startsWith('/jobs') || pathname.startsWith('/shifts') || pathname.startsWith('/profile') || pathname.startsWith('/messages')

  if (token && isAuthPage) {
    return NextResponse.redirect(new URL('/jobs', request.url))
  }

  if (!token && isDashboardPage) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
