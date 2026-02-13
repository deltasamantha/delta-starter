// ============================================================
// Application-wide constants
// ============================================================

export const APP_NAME = '__DISPLAY_NAME__'
export const APP_DESCRIPTION = 'Online Staffing Platform'

// ============================================================
// API
// ============================================================

export const API_VERSION = 'v1'
export const DEFAULT_PAGE_SIZE = 20
export const MAX_PAGE_SIZE = 100

// ============================================================
// Status display maps (for UI labels + colors)
// ============================================================

export const JOB_STATUS_LABELS = {
  draft: 'Draft',
  published: 'Published',
  closed: 'Closed',
  filled: 'Filled',
  cancelled: 'Cancelled',
} as const

export const JOB_STATUS_COLORS = {
  draft: 'gray',
  published: 'green',
  closed: 'orange',
  filled: 'blue',
  cancelled: 'red',
} as const

export const APPLICATION_STATUS_LABELS = {
  pending: 'Pending',
  reviewed: 'Under Review',
  shortlisted: 'Shortlisted',
  accepted: 'Accepted',
  rejected: 'Rejected',
  withdrawn: 'Withdrawn',
} as const

export const APPLICATION_STATUS_COLORS = {
  pending: 'gray',
  reviewed: 'blue',
  shortlisted: 'purple',
  accepted: 'green',
  rejected: 'red',
  withdrawn: 'orange',
} as const

export const SHIFT_STATUS_LABELS = {
  scheduled: 'Scheduled',
  in_progress: 'In Progress',
  completed: 'Completed',
  cancelled: 'Cancelled',
  no_show: 'No Show',
} as const

export const JOB_TYPE_LABELS = {
  full_time: 'Full Time',
  part_time: 'Part Time',
  contract: 'Contract',
  temporary: 'Temporary',
  per_diem: 'Per Diem',
} as const

export const SKILL_LEVEL_LABELS = {
  beginner: 'Beginner',
  intermediate: 'Intermediate',
  advanced: 'Advanced',
  expert: 'Expert',
} as const

export const AVAILABILITY_LABELS = {
  available: 'Available',
  limited: 'Limited Availability',
  unavailable: 'Unavailable',
} as const

// ============================================================
// User roles & permissions
// ============================================================

export const ROLE_PERMISSIONS = {
  worker: [
    'jobs:view',
    'jobs:apply',
    'profile:edit',
    'shifts:view_own',
    'shifts:clock',
    'messages:send',
    'reviews:create',
  ],
  employer: [
    'jobs:view',
    'jobs:create',
    'jobs:edit',
    'jobs:delete',
    'applications:view',
    'applications:manage',
    'shifts:view',
    'shifts:create',
    'shifts:manage',
    'company:edit',
    'messages:send',
    'reviews:create',
  ],
  admin: ['*'], // All permissions
} as const

export type Permission = (typeof ROLE_PERMISSIONS.worker)[number] | '*'

// ============================================================
// Validation limits (used in both schemas and UI)
// ============================================================

export const LIMITS = {
  MIN_PASSWORD_LENGTH: 8,
  MAX_BIO_LENGTH: 2000,
  MAX_COVER_NOTE_LENGTH: 2000,
  MAX_JOB_DESCRIPTION_LENGTH: 10000,
  MAX_HOURLY_RATE: 10000,
  MAX_SEARCH_RADIUS_KM: 500,
  DEFAULT_SEARCH_RADIUS_KM: 50,
  MAX_SKILLS: 50,
  MAX_FILE_SIZE_MB: 10,
} as const
