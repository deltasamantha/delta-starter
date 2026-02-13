import type { Job, WorkerProfile } from '__SCOPE__/shared'

export interface MatchScore {
  workerId: string
  jobId: string
  overallScore: number
  skillMatch: number
  rateMatch: number
  locationMatch: number
  availabilityMatch: number
}

/**
 * Calculate how well a worker matches a job posting.
 * Returns a score from 0-100.
 */
export function calculateMatchScore(worker: WorkerProfile, job: Job): MatchScore {
  const skillMatch = calculateSkillMatch(worker.skills.map((s) => s.name), job.skills)
  const rateMatch = calculateRateMatch(worker.hourlyRate, job.hourlyRateMin, job.hourlyRateMax)
  const locationMatch = calculateLocationMatch(
    worker.latitude,
    worker.longitude,
    job.latitude,
    job.longitude,
    worker.radiusKm,
    job.isRemote,
  )
  const availabilityMatch = worker.availability === 'available' ? 100 : worker.availability === 'limited' ? 50 : 0

  // Weighted scoring
  const overallScore = Math.round(
    skillMatch * 0.4 + rateMatch * 0.2 + locationMatch * 0.25 + availabilityMatch * 0.15,
  )

  return {
    workerId: worker.id,
    jobId: job.id,
    overallScore,
    skillMatch,
    rateMatch,
    locationMatch,
    availabilityMatch,
  }
}

/**
 * Calculate skill overlap percentage.
 */
export function calculateSkillMatch(workerSkills: string[], jobSkills: string[]): number {
  if (jobSkills.length === 0) return 100
  const normalizedWorker = workerSkills.map((s) => s.toLowerCase().trim())
  const normalizedJob = jobSkills.map((s) => s.toLowerCase().trim())
  const matchCount = normalizedJob.filter((s) => normalizedWorker.includes(s)).length
  return Math.round((matchCount / normalizedJob.length) * 100)
}

/**
 * Calculate rate compatibility (0-100).
 */
export function calculateRateMatch(
  workerRate: number | undefined,
  jobMin: number,
  jobMax: number,
): number {
  if (!workerRate) return 50 // neutral if not specified
  if (workerRate >= jobMin && workerRate <= jobMax) return 100
  if (workerRate < jobMin) {
    const diff = jobMin - workerRate
    return Math.max(0, 100 - diff * 5)
  }
  const diff = workerRate - jobMax
  return Math.max(0, 100 - diff * 5)
}

/**
 * Calculate location proximity score using Haversine distance.
 */
export function calculateLocationMatch(
  workerLat?: number,
  workerLng?: number,
  jobLat?: number,
  jobLng?: number,
  workerRadiusKm?: number,
  isRemote?: boolean,
): number {
  if (isRemote) return 100
  if (!workerLat || !workerLng || !jobLat || !jobLng) return 50

  const distance = haversineDistance(workerLat, workerLng, jobLat, jobLng)
  const radius = workerRadiusKm || 50

  if (distance <= radius * 0.5) return 100
  if (distance <= radius) return 75
  if (distance <= radius * 1.5) return 40
  return 0
}

/**
 * Haversine formula — distance between two GPS coordinates in km.
 */
export function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371 // Earth's radius in km
  const dLat = toRad(lat2 - lat1)
  const dLng = toRad(lng2 - lng1)
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180)
}
