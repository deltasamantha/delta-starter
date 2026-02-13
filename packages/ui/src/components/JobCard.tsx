'use client'

import { Card, H4, Paragraph, XStack, YStack, SizableText } from 'tamagui'
import { JOB_TYPE_LABELS } from '__SCOPE__/shared'
import type { Job } from '__SCOPE__/shared'
import { Badge } from './Badge'

interface JobCardProps {
  job: Pick<
    Job,
    'title' | 'hourlyRateMin' | 'hourlyRateMax' | 'jobType' | 'location' | 'isRemote' | 'isUrgent'
  >
  companyName?: string
  onPress?: () => void
}

export function JobCard({ job, companyName, onPress }: JobCardProps) {
  return (
    <Card
      elevate
      bordered
      padding="$4"
      gap="$2"
      pressTheme
      animation="fast"
      hoverStyle={{ scale: 1.02, borderColor: '$primaryLight' }}
      pressStyle={{ scale: 0.98 }}
      onPress={onPress}
      cursor="pointer"
    >
      <XStack justifyContent="space-between" alignItems="flex-start">
        <YStack flex={1} gap="$1">
          <H4 numberOfLines={1}>{job.title}</H4>
          {companyName && (
            <SizableText size="$3" color="$colorMuted">
              {companyName}
            </SizableText>
          )}
        </YStack>
        {job.isUrgent && <Badge variant="error">Urgent</Badge>}
      </XStack>

      <XStack gap="$2" flexWrap="wrap">
        <Badge variant="primary">{JOB_TYPE_LABELS[job.jobType]}</Badge>
        {job.isRemote && <Badge variant="success">Remote</Badge>}
      </XStack>

      <XStack justifyContent="space-between" alignItems="center" marginTop="$2">
        <SizableText size="$4" fontWeight="600" color="$primary">
          ${job.hourlyRateMin} - ${job.hourlyRateMax}/hr
        </SizableText>
        <SizableText size="$3" color="$colorMuted">
          {job.location}
        </SizableText>
      </XStack>
    </Card>
  )
}
