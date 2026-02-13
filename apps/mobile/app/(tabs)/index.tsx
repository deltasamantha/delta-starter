import { ScrollView } from 'react-native'
import { H2, YStack, Paragraph, Spinner } from '__SCOPE__/ui'
import { JobCard } from '__SCOPE__/ui'
import { APP_NAME } from '__SCOPE__/shared'

export default function JobsScreen() {
  // TODO: Wire up with useJobs() from __SCOPE__/api-client

  return (
    <ScrollView>
      <YStack padding="$4" gap="$4">
        <H2>Find Work</H2>
        <Paragraph color="$colorMuted">
          Browse available positions near you
        </Paragraph>

        {/* Example JobCard — same component used on web */}
        <JobCard
          job={{
            title: 'Warehouse Associate',
            hourlyRateMin: 18,
            hourlyRateMax: 22,
            jobType: 'temporary',
            location: 'Espoo, Finland',
            isRemote: false,
            isUrgent: true,
          }}
          companyName="LogiCorp Oy"
          onPress={() => {
            // TODO: Navigate to job detail
          }}
        />

        <JobCard
          job={{
            title: 'Event Staff',
            hourlyRateMin: 15,
            hourlyRateMax: 20,
            jobType: 'per_diem',
            location: 'Helsinki, Finland',
            isRemote: false,
            isUrgent: false,
          }}
          companyName="EventPro Finland"
          onPress={() => {}}
        />
      </YStack>
    </ScrollView>
  )
}
