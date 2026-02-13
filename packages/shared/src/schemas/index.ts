import { z } from 'zod'

// ============================================================
// USER & AUTH
// ============================================================

export const UserRole = z.enum(['worker', 'employer', 'admin'])
export type UserRole = z.infer<typeof UserRole>

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  phone: z.string().optional(),
  role: UserRole,
  avatarUrl: z.string().url().optional(),
  isVerified: z.boolean().default(false),
  isActive: z.boolean().default(true),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
})

export const RegisterSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  role: UserRole,
})

export const LoginSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(1, 'Password is required'),
})

// ============================================================
// WORKER PROFILE
// ============================================================

export const SkillLevel = z.enum(['beginner', 'intermediate', 'advanced', 'expert'])
export type SkillLevel = z.infer<typeof SkillLevel>

export const WorkerProfileSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  headline: z.string().max(200).optional(),
  bio: z.string().max(2000).optional(),
  skills: z.array(
    z.object({
      name: z.string(),
      level: SkillLevel,
    }),
  ),
  hourlyRate: z.number().min(0).max(10000).optional(),
  availability: z.enum(['available', 'limited', 'unavailable']).default('available'),
  location: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  radiusKm: z.number().min(1).max(500).default(50),
  documentsVerified: z.boolean().default(false),
  rating: z.number().min(0).max(5).default(0),
  totalJobsCompleted: z.number().int().min(0).default(0),
})

// ============================================================
// COMPANY
// ============================================================

export const CompanySchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  industry: z.string().optional(),
  logoUrl: z.string().url().optional(),
  website: z.string().url().optional(),
  address: z.string().optional(),
  isVerified: z.boolean().default(false),
  ownerId: z.string().uuid(),
  createdAt: z.coerce.date(),
})

// ============================================================
// JOB POSTING
// ============================================================

export const JobStatus = z.enum(['draft', 'published', 'closed', 'filled', 'cancelled'])
export type JobStatus = z.infer<typeof JobStatus>

export const JobType = z.enum(['full_time', 'part_time', 'contract', 'temporary', 'per_diem'])
export type JobType = z.infer<typeof JobType>

export const JobSchema = z.object({
  id: z.string().uuid(),
  companyId: z.string().uuid(),
  title: z.string().min(1).max(200),
  description: z.string().min(10).max(10000),
  requirements: z.array(z.string()),
  skills: z.array(z.string()),
  jobType: JobType,
  status: JobStatus.default('draft'),
  hourlyRateMin: z.number().min(0),
  hourlyRateMax: z.number().min(0),
  location: z.string(),
  isRemote: z.boolean().default(false),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  slotsTotal: z.number().int().min(1).default(1),
  slotsFilled: z.number().int().min(0).default(0),
  isUrgent: z.boolean().default(false),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
})

export const CreateJobSchema = JobSchema.omit({
  id: true,
  companyId: true,
  slotsFilled: true,
  status: true,
  createdAt: true,
  updatedAt: true,
}).refine((data) => data.hourlyRateMax >= data.hourlyRateMin, {
  message: 'Maximum rate must be greater than or equal to minimum rate',
  path: ['hourlyRateMax'],
})

// ============================================================
// APPLICATION
// ============================================================

export const ApplicationStatus = z.enum([
  'pending',
  'reviewed',
  'shortlisted',
  'accepted',
  'rejected',
  'withdrawn',
])
export type ApplicationStatus = z.infer<typeof ApplicationStatus>

export const ApplicationSchema = z.object({
  id: z.string().uuid(),
  jobId: z.string().uuid(),
  workerId: z.string().uuid(),
  status: ApplicationStatus.default('pending'),
  coverNote: z.string().max(2000).optional(),
  proposedRate: z.number().min(0).optional(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
})

// ============================================================
// SHIFT / TIMESHEET
// ============================================================

export const ShiftStatus = z.enum(['scheduled', 'in_progress', 'completed', 'cancelled', 'no_show'])
export type ShiftStatus = z.infer<typeof ShiftStatus>

export const ShiftSchema = z.object({
  id: z.string().uuid(),
  jobId: z.string().uuid(),
  workerId: z.string().uuid(),
  date: z.coerce.date(),
  startTime: z.string(), // HH:mm format
  endTime: z.string(),
  status: ShiftStatus.default('scheduled'),
  clockInTime: z.coerce.date().optional(),
  clockOutTime: z.coerce.date().optional(),
  breakMinutes: z.number().int().min(0).default(0),
  totalHours: z.number().min(0).optional(),
  hourlyRate: z.number().min(0),
  totalPay: z.number().min(0).optional(),
  notes: z.string().optional(),
})

// ============================================================
// REVIEW
// ============================================================

export const ReviewSchema = z.object({
  id: z.string().uuid(),
  reviewerId: z.string().uuid(),
  revieweeId: z.string().uuid(),
  jobId: z.string().uuid(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(1000).optional(),
  createdAt: z.coerce.date(),
})

// Infer all types from schemas
export type User = z.infer<typeof UserSchema>
export type Register = z.infer<typeof RegisterSchema>
export type Login = z.infer<typeof LoginSchema>
export type WorkerProfile = z.infer<typeof WorkerProfileSchema>
export type Company = z.infer<typeof CompanySchema>
export type Job = z.infer<typeof JobSchema>
export type CreateJob = z.infer<typeof CreateJobSchema>
export type Application = z.infer<typeof ApplicationSchema>
export type Shift = z.infer<typeof ShiftSchema>
export type Review = z.infer<typeof ReviewSchema>
