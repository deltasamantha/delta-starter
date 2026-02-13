import type { Shift } from '__SCOPE__/shared'

/**
 * Calculate total hours worked from clock in/out times, subtracting break.
 */
export function calculateShiftHours(
  clockIn: Date,
  clockOut: Date,
  breakMinutes: number = 0,
): number {
  const diffMs = clockOut.getTime() - clockIn.getTime()
  const totalMinutes = diffMs / (1000 * 60)
  const workedMinutes = totalMinutes - breakMinutes
  return Math.max(0, Math.round((workedMinutes / 60) * 100) / 100)
}

/**
 * Calculate total pay for a shift.
 */
export function calculateShiftPay(totalHours: number, hourlyRate: number): number {
  return Math.round(totalHours * hourlyRate * 100) / 100
}

/**
 * Check if two time ranges overlap (for conflict detection).
 */
export function hasTimeConflict(
  start1: Date,
  end1: Date,
  start2: Date,
  end2: Date,
): boolean {
  return start1 < end2 && start2 < end1
}

/**
 * Calculate overtime hours (above standard 8-hour day or 40-hour week).
 */
export function calculateOvertimeHours(
  totalHours: number,
  threshold: number = 8,
): { regular: number; overtime: number } {
  if (totalHours <= threshold) {
    return { regular: totalHours, overtime: 0 }
  }
  return {
    regular: threshold,
    overtime: Math.round((totalHours - threshold) * 100) / 100,
  }
}

/**
 * Calculate weekly hours from an array of shifts.
 */
export function calculateWeeklyHours(shifts: Pick<Shift, 'totalHours'>[]): number {
  return shifts.reduce((total, shift) => total + (shift.totalHours || 0), 0)
}

/**
 * Parse HH:mm time string to Date on a given date.
 */
export function parseTimeToDate(date: Date, timeStr: string): Date {
  const [hours, minutes] = timeStr.split(':').map(Number)
  const result = new Date(date)
  result.setHours(hours, minutes, 0, 0)
  return result
}

/**
 * Format hours as "Xh Ym" string.
 */
export function formatHoursMinutes(totalHours: number): string {
  const hours = Math.floor(totalHours)
  const minutes = Math.round((totalHours - hours) * 60)
  if (minutes === 0) return `${hours}h`
  return `${hours}h ${minutes}m`
}
