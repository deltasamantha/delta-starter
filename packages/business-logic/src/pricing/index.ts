/**
 * Platform fee configuration.
 */
export interface FeeConfig {
  workerFeePercent: number   // Percentage taken from worker's pay
  employerFeePercent: number // Percentage added to employer's cost
  minimumFee: number         // Minimum platform fee
}

export const DEFAULT_FEE_CONFIG: FeeConfig = {
  workerFeePercent: 5,
  employerFeePercent: 15,
  minimumFee: 1.0,
}

/**
 * Calculate the cost breakdown for a shift.
 */
export interface ShiftCostBreakdown {
  hoursWorked: number
  baseRate: number
  baseCost: number
  employerFee: number
  employerTotal: number
  workerFee: number
  workerPayout: number
  platformRevenue: number
}

export function calculateShiftCost(
  hoursWorked: number,
  hourlyRate: number,
  config: FeeConfig = DEFAULT_FEE_CONFIG,
): ShiftCostBreakdown {
  const baseCost = round(hoursWorked * hourlyRate)
  const employerFee = round(Math.max(baseCost * (config.employerFeePercent / 100), config.minimumFee))
  const workerFee = round(Math.max(baseCost * (config.workerFeePercent / 100), config.minimumFee))

  return {
    hoursWorked,
    baseRate: hourlyRate,
    baseCost,
    employerFee,
    employerTotal: round(baseCost + employerFee),
    workerFee,
    workerPayout: round(baseCost - workerFee),
    platformRevenue: round(employerFee + workerFee),
  }
}

/**
 * Calculate invoice totals from multiple shifts.
 */
export interface InvoiceSummary {
  totalShifts: number
  totalHours: number
  subtotal: number
  platformFees: number
  total: number
}

export function calculateInvoice(
  shifts: Array<{ hoursWorked: number; hourlyRate: number }>,
  config: FeeConfig = DEFAULT_FEE_CONFIG,
): InvoiceSummary {
  let totalHours = 0
  let subtotal = 0
  let platformFees = 0

  for (const shift of shifts) {
    const breakdown = calculateShiftCost(shift.hoursWorked, shift.hourlyRate, config)
    totalHours += shift.hoursWorked
    subtotal += breakdown.baseCost
    platformFees += breakdown.employerFee
  }

  return {
    totalShifts: shifts.length,
    totalHours: round(totalHours),
    subtotal: round(subtotal),
    platformFees: round(platformFees),
    total: round(subtotal + platformFees),
  }
}

/**
 * Format currency for display.
 */
export function formatCurrency(amount: number, currency: string = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(amount)
}

function round(n: number): number {
  return Math.round(n * 100) / 100
}
