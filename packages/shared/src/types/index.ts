import type {
  User,
  Job,
  Application,
  WorkerProfile,
  Company,
  Shift,
  Review,
} from '../schemas'

// ============================================================
// API Response wrappers
// ============================================================

export interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
}

export interface ApiErrorResponse {
  success: false
  error: string
  details?: Record<string, string[]>
  statusCode: number
}

export interface PaginatedResponse<T> {
  success: true
  data: T[]
  pagination: {
    page: number
    pageSize: number
    total: number
    totalPages: number
    hasNext: boolean
    hasPrev: boolean
  }
}

// ============================================================
// Auth types
// ============================================================

export interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export interface AuthUser {
  id: string
  email: string
  firstName: string
  lastName: string
  role: User['role']
  avatarUrl?: string
}

export interface AuthSession {
  user: AuthUser
  tokens: AuthTokens
}

// ============================================================
// Query / filter types (shared between client & server)
// ============================================================

export interface JobFilters {
  search?: string
  jobType?: Job['jobType'][]
  status?: Job['status']
  minRate?: number
  maxRate?: number
  location?: string
  radiusKm?: number
  latitude?: number
  longitude?: number
  isRemote?: boolean
  isUrgent?: boolean
  skills?: string[]
  sortBy?: 'createdAt' | 'hourlyRateMin' | 'hourlyRateMax' | 'distance'
  sortOrder?: 'asc' | 'desc'
  page?: number
  pageSize?: number
}

export interface WorkerSearchFilters {
  search?: string
  skills?: string[]
  minRate?: number
  maxRate?: number
  availability?: WorkerProfile['availability']
  location?: string
  radiusKm?: number
  latitude?: number
  longitude?: number
  minRating?: number
  sortBy?: 'rating' | 'hourlyRate' | 'totalJobsCompleted' | 'distance'
  sortOrder?: 'asc' | 'desc'
  page?: number
  pageSize?: number
}

// ============================================================
// Dashboard stats
// ============================================================

export interface WorkerDashboardStats {
  upcomingShifts: number
  completedShifts: number
  pendingApplications: number
  totalEarnings: number
  averageRating: number
}

export interface EmployerDashboardStats {
  activeJobs: number
  totalApplications: number
  pendingApplications: number
  scheduledShifts: number
  totalSpend: number
}

// ============================================================
// Notification types
// ============================================================

export type NotificationType =
  | 'application_received'
  | 'application_status_changed'
  | 'shift_assigned'
  | 'shift_reminder'
  | 'shift_cancelled'
  | 'new_message'
  | 'review_received'
  | 'payment_processed'

export interface Notification {
  id: string
  userId: string
  type: NotificationType
  title: string
  body: string
  data?: Record<string, string>
  isRead: boolean
  createdAt: Date
}
