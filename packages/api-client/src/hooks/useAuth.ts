import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { ApiResponse, AuthSession, Register, Login, AuthUser } from '__SCOPE__/shared'
import type { ApiClient } from '../client'

export const authKeys = {
  session: ['auth', 'session'] as const,
  user: ['auth', 'user'] as const,
}

export function createAuthHooks(client: ApiClient) {
  function useLogin() {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: Login) =>
        client.post<ApiResponse<AuthSession>>('/api/v1/auth/login', data),
      onSuccess: (response) => {
        queryClient.setQueryData(authKeys.session, response.data)
      },
    })
  }

  function useRegister() {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: Register) =>
        client.post<ApiResponse<AuthSession>>('/api/v1/auth/register', data),
      onSuccess: (response) => {
        queryClient.setQueryData(authKeys.session, response.data)
      },
    })
  }

  function useLogout() {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: () => client.post('/api/v1/auth/logout'),
      onSuccess: () => {
        queryClient.clear()
      },
    })
  }

  function useCurrentUser() {
    return useQuery({
      queryKey: authKeys.user,
      queryFn: () => client.get<ApiResponse<AuthUser>>('/api/v1/auth/me'),
      retry: false,
      staleTime: 5 * 60 * 1000, // 5 minutes
    })
  }

  return { useLogin, useRegister, useLogout, useCurrentUser }
}
