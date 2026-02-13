'use client'

import {
  APPLICATION_STATUS_LABELS,
  APPLICATION_STATUS_COLORS,
  JOB_STATUS_LABELS,
  JOB_STATUS_COLORS,
  SHIFT_STATUS_LABELS,
} from '__SCOPE__/shared'
import type { ApplicationStatus, JobStatus, ShiftStatus } from '__SCOPE__/shared'
import { Badge } from './Badge'

type ColorMapping = 'primary' | 'secondary' | 'success' | 'error' | 'warning' | 'info' | 'neutral'

const statusColorMap: Record<string, ColorMapping> = {
  gray: 'neutral',
  green: 'success',
  blue: 'primary',
  purple: 'info',
  red: 'error',
  orange: 'warning',
}

export function ApplicationStatusBadge({ status }: { status: ApplicationStatus }) {
  const label = APPLICATION_STATUS_LABELS[status]
  const colorKey = APPLICATION_STATUS_COLORS[status]
  return <Badge variant={statusColorMap[colorKey] || 'neutral'}>{label}</Badge>
}

export function JobStatusBadge({ status }: { status: JobStatus }) {
  const label = JOB_STATUS_LABELS[status]
  const colorKey = JOB_STATUS_COLORS[status]
  return <Badge variant={statusColorMap[colorKey] || 'neutral'}>{label}</Badge>
}

export function ShiftStatusBadge({ status }: { status: ShiftStatus }) {
  const label = SHIFT_STATUS_LABELS[status]
  const colorMap: Record<ShiftStatus, ColorMapping> = {
    scheduled: 'primary',
    in_progress: 'warning',
    completed: 'success',
    cancelled: 'error',
    no_show: 'error',
  }
  return <Badge variant={colorMap[status]}>{label}</Badge>
}
