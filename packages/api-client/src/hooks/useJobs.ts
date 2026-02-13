import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import type {
  ApiResponse,
  PaginatedResponse,
  Job,
  CreateJob,
  JobFilters,
  Application,
} from '__SCOPE__/shared'
import type { ApiClient } from '../client'

// Query key factory
export const jobKeys = {
  all: ['jobs'] as const,
  lists: () => [...jobKeys.all, 'list'] as const,
  list: (filters: JobFilters) => [...jobKeys.lists(), filters] as const,
  details: () => [...jobKeys.all, 'detail'] as const,
  detail: (id: string) => [...jobKeys.details(), id] as const,
  applications: (jobId: string) => [...jobKeys.all, 'applications', jobId] as const,
}

export function createJobHooks(client: ApiClient) {
  // Fetch paginated job listings
  function useJobs(filters: JobFilters = {}) {
    return useQuery({
      queryKey: jobKeys.list(filters),
      queryFn: () =>
        client.get<PaginatedResponse<Job>>('/api/v1/jobs', {
          params: filters as Record<string, string | number | boolean | undefined>,
        }),
    })
  }

  // Fetch single job by ID
  function useJob(id: string) {
    return useQuery({
      queryKey: jobKeys.detail(id),
      queryFn: () => client.get<ApiResponse<Job>>(`/api/v1/jobs/${id}`),
      enabled: !!id,
    })
  }

  // Create a new job
  function useCreateJob() {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: CreateJob) =>
        client.post<ApiResponse<Job>>('/api/v1/jobs', data),
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: jobKeys.lists() })
      },
    })
  }

  // Update a job
  function useUpdateJob(id: string) {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: Partial<Job>) =>
        client.patch<ApiResponse<Job>>(`/api/v1/jobs/${id}`, data),
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: jobKeys.detail(id) })
        queryClient.invalidateQueries({ queryKey: jobKeys.lists() })
      },
    })
  }

  // Apply to a job
  function useApplyToJob() {
    const queryClient = useQueryClient()
    return useMutation({
      mutationFn: (data: { jobId: string; coverNote?: string; proposedRate?: number }) =>
        client.post<ApiResponse<Application>>(`/api/v1/jobs/${data.jobId}/apply`, data),
      onSuccess: (_, variables) => {
        queryClient.invalidateQueries({ queryKey: jobKeys.detail(variables.jobId) })
      },
    })
  }

  // Get applications for a job (employer view)
  function useJobApplications(jobId: string) {
    return useQuery({
      queryKey: jobKeys.applications(jobId),
      queryFn: () =>
        client.get<PaginatedResponse<Application>>(`/api/v1/jobs/${jobId}/applications`),
      enabled: !!jobId,
    })
  }

  return {
    useJobs,
    useJob,
    useCreateJob,
    useUpdateJob,
    useApplyToJob,
    useJobApplications,
  }
}
