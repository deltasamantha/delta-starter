import type { ApiResponse, ApiErrorResponse, PaginatedResponse, AuthTokens } from '__SCOPE__/shared'

type RequestMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'

interface RequestOptions {
  headers?: Record<string, string>
  params?: Record<string, string | number | boolean | undefined>
  signal?: AbortSignal
}

export class ApiClientError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public details?: Record<string, string[]>,
  ) {
    super(message)
    this.name = 'ApiClientError'
  }
}

export class ApiClient {
  private baseUrl: string
  private getAccessToken: () => string | null
  private onTokenRefresh?: () => Promise<AuthTokens | null>
  private onUnauthorized?: () => void

  constructor(config: {
    baseUrl: string
    getAccessToken: () => string | null
    onTokenRefresh?: () => Promise<AuthTokens | null>
    onUnauthorized?: () => void
  }) {
    this.baseUrl = config.baseUrl.replace(/\/$/, '')
    this.getAccessToken = config.getAccessToken
    this.onTokenRefresh = config.onTokenRefresh
    this.onUnauthorized = config.onUnauthorized
  }

  private buildUrl(path: string, params?: Record<string, string | number | boolean | undefined>): string {
    const url = new URL(`${this.baseUrl}${path}`)
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          url.searchParams.set(key, String(value))
        }
      })
    }
    return url.toString()
  }

  private async request<T>(
    method: RequestMethod,
    path: string,
    body?: unknown,
    options?: RequestOptions,
  ): Promise<T> {
    const url = this.buildUrl(path, options?.params)
    const token = this.getAccessToken()

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...options?.headers,
    }

    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }

    const response = await fetch(url, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
      signal: options?.signal,
    })

    // Handle 401 — try token refresh
    if (response.status === 401 && this.onTokenRefresh) {
      const newTokens = await this.onTokenRefresh()
      if (newTokens) {
        headers['Authorization'] = `Bearer ${newTokens.accessToken}`
        const retryResponse = await fetch(url, {
          method,
          headers,
          body: body ? JSON.stringify(body) : undefined,
          signal: options?.signal,
        })
        if (retryResponse.ok) {
          return retryResponse.json()
        }
      }
      this.onUnauthorized?.()
      throw new ApiClientError('Unauthorized', 401)
    }

    if (!response.ok) {
      const error = (await response.json().catch(() => null)) as ApiErrorResponse | null
      throw new ApiClientError(
        error?.error || `Request failed with status ${response.status}`,
        response.status,
        error?.details,
      )
    }

    return response.json()
  }

  // Convenience methods
  get<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('GET', path, undefined, options)
  }

  post<T>(path: string, body?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('POST', path, body, options)
  }

  put<T>(path: string, body?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('PUT', path, body, options)
  }

  patch<T>(path: string, body?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('PATCH', path, body, options)
  }

  delete<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('DELETE', path, undefined, options)
  }
}
