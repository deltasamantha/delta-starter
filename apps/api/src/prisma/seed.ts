import { PrismaClient } from '@prisma/client'
import { createHash } from 'crypto'

const prisma = new PrismaClient()

// Simple password hash for seeding (use bcrypt in production)
function hashPassword(password: string): string {
  return createHash('sha256').update(password).digest('hex')
}

async function main() {
  console.log('🌱 Seeding database...')

  // Clean existing data
  await prisma.notification.deleteMany()
  await prisma.review.deleteMany()
  await prisma.shift.deleteMany()
  await prisma.application.deleteMany()
  await prisma.job.deleteMany()
  await prisma.workerProfile.deleteMany()
  await prisma.company.deleteMany()
  await prisma.user.deleteMany()

  console.log('  Cleared existing data')

  // ─── Users ──────────────────────────────────────────────────────
  const adminUser = await prisma.user.create({
    data: {
      email: 'admin@__SLUG__.com',
      passwordHash: hashPassword('Admin123!'),
      firstName: 'System',
      lastName: 'Admin',
      role: 'admin',
      isVerified: true,
    },
  })

  const employer1 = await prisma.user.create({
    data: {
      email: 'maria@logicorp.fi',
      passwordHash: hashPassword('Employer123!'),
      firstName: 'Maria',
      lastName: 'Virtanen',
      role: 'employer',
      isVerified: true,
    },
  })

  const employer2 = await prisma.user.create({
    data: {
      email: 'erik@eventpro.fi',
      passwordHash: hashPassword('Employer123!'),
      firstName: 'Erik',
      lastName: 'Lindström',
      role: 'employer',
      isVerified: true,
    },
  })

  const worker1 = await prisma.user.create({
    data: {
      email: 'anna@example.com',
      passwordHash: hashPassword('Worker123!'),
      firstName: 'Anna',
      lastName: 'Korhonen',
      role: 'worker',
      isVerified: true,
    },
  })

  const worker2 = await prisma.user.create({
    data: {
      email: 'mikko@example.com',
      passwordHash: hashPassword('Worker123!'),
      firstName: 'Mikko',
      lastName: 'Mäkinen',
      role: 'worker',
      isVerified: true,
    },
  })

  const worker3 = await prisma.user.create({
    data: {
      email: 'sofia@example.com',
      passwordHash: hashPassword('Worker123!'),
      firstName: 'Sofia',
      lastName: 'Niemi',
      role: 'worker',
      isVerified: true,
    },
  })

  console.log('  Created 6 users (1 admin, 2 employers, 3 workers)')

  // ─── Worker Profiles ───────────────────────────────────────────
  await prisma.workerProfile.createMany({
    data: [
      {
        userId: worker1.id,
        headline: 'Experienced warehouse & logistics worker',
        bio: 'Reliable worker with 5+ years in warehouse operations. Forklift certified.',
        skills: JSON.stringify([
          { name: 'Forklift', level: 'expert' },
          { name: 'Warehouse', level: 'advanced' },
          { name: 'Inventory Management', level: 'intermediate' },
          { name: 'Packing', level: 'advanced' },
        ]),
        hourlyRate: 18,
        availability: 'available',
        location: 'Espoo, Finland',
        latitude: 60.2055,
        longitude: 24.6559,
        radiusKm: 30,
        rating: 4.7,
        totalJobsCompleted: 42,
        documentsVerified: true,
      },
      {
        userId: worker2.id,
        headline: 'Event staff & hospitality professional',
        bio: 'Friendly and energetic. Experienced in events, catering, and customer service.',
        skills: JSON.stringify([
          { name: 'Event Setup', level: 'advanced' },
          { name: 'Customer Service', level: 'expert' },
          { name: 'Catering', level: 'intermediate' },
          { name: 'Bartending', level: 'beginner' },
        ]),
        hourlyRate: 16,
        availability: 'available',
        location: 'Helsinki, Finland',
        latitude: 60.1699,
        longitude: 24.9384,
        radiusKm: 25,
        rating: 4.5,
        totalJobsCompleted: 28,
        documentsVerified: true,
      },
      {
        userId: worker3.id,
        headline: 'Retail & office administration',
        bio: 'Detail-oriented professional with retail and admin experience.',
        skills: JSON.stringify([
          { name: 'Retail', level: 'advanced' },
          { name: 'Data Entry', level: 'expert' },
          { name: 'Office Admin', level: 'intermediate' },
          { name: 'Customer Service', level: 'advanced' },
        ]),
        hourlyRate: 17,
        availability: 'limited',
        location: 'Vantaa, Finland',
        latitude: 60.2934,
        longitude: 25.0378,
        radiusKm: 40,
        rating: 4.3,
        totalJobsCompleted: 15,
        documentsVerified: false,
      },
    ],
  })

  console.log('  Created 3 worker profiles')

  // ─── Companies ─────────────────────────────────────────────────
  const company1 = await prisma.company.create({
    data: {
      name: 'LogiCorp Oy',
      description: 'Leading logistics and warehousing solutions provider in the Helsinki metropolitan area.',
      industry: 'Logistics & Warehousing',
      website: 'https://logicorp.fi',
      address: 'Keilaranta 1, 02150 Espoo',
      isVerified: true,
      ownerId: employer1.id,
    },
  })

  const company2 = await prisma.company.create({
    data: {
      name: 'EventPro Finland',
      description: 'Full-service event management and staffing company.',
      industry: 'Events & Hospitality',
      website: 'https://eventpro.fi',
      address: 'Mannerheimintie 12, 00100 Helsinki',
      isVerified: true,
      ownerId: employer2.id,
    },
  })

  console.log('  Created 2 companies')

  // ─── Jobs ──────────────────────────────────────────────────────
  const job1 = await prisma.job.create({
    data: {
      companyId: company1.id,
      title: 'Warehouse Associate — Peak Season',
      description: 'Join our team for the peak holiday season! You\'ll handle receiving, sorting, packing, and shipping of goods. Fast-paced environment with great team energy.',
      requirements: JSON.stringify(['Must be able to lift 20kg', 'Standing for extended periods', 'Basic Finnish or English']),
      skills: JSON.stringify(['Warehouse', 'Packing', 'Forklift']),
      jobType: 'temporary',
      status: 'published',
      hourlyRateMin: 16,
      hourlyRateMax: 22,
      location: 'Espoo, Finland',
      latitude: 60.2055,
      longitude: 24.6559,
      isRemote: false,
      slotsTotal: 5,
      slotsFilled: 1,
      isUrgent: true,
    },
  })

  const job2 = await prisma.job.create({
    data: {
      companyId: company2.id,
      title: 'Event Staff — Corporate Gala',
      description: 'We need friendly, professional staff for an upcoming corporate gala event. Duties include guest registration, coat check, serving, and general event support.',
      requirements: JSON.stringify(['Professional appearance', 'Basic English required', 'Customer service experience preferred']),
      skills: JSON.stringify(['Event Setup', 'Customer Service', 'Catering']),
      jobType: 'per_diem',
      status: 'published',
      hourlyRateMin: 15,
      hourlyRateMax: 20,
      location: 'Helsinki, Finland',
      latitude: 60.1699,
      longitude: 24.9384,
      isRemote: false,
      slotsTotal: 10,
      isUrgent: false,
    },
  })

  const job3 = await prisma.job.create({
    data: {
      companyId: company1.id,
      title: 'Inventory Data Entry Clerk',
      description: 'Temporary position for inventory count and data entry. Must be detail-oriented and comfortable with spreadsheets and inventory software.',
      requirements: JSON.stringify(['Computer literacy', 'Attention to detail', 'Finnish language']),
      skills: JSON.stringify(['Data Entry', 'Inventory Management', 'Office Admin']),
      jobType: 'contract',
      status: 'published',
      hourlyRateMin: 17,
      hourlyRateMax: 21,
      location: 'Espoo, Finland',
      latitude: 60.2055,
      longitude: 24.6559,
      isRemote: false,
      slotsTotal: 2,
      isUrgent: false,
    },
  })

  await prisma.job.create({
    data: {
      companyId: company2.id,
      title: 'Weekend Bartender',
      description: 'Looking for experienced bartenders for weekend events throughout the Helsinki area.',
      requirements: JSON.stringify(['Bartending experience', '18+ years old', 'Hygiene passport']),
      skills: JSON.stringify(['Bartending', 'Customer Service']),
      jobType: 'part_time',
      status: 'draft',
      hourlyRateMin: 18,
      hourlyRateMax: 25,
      location: 'Helsinki, Finland',
      latitude: 60.1699,
      longitude: 24.9384,
      isRemote: false,
      slotsTotal: 3,
    },
  })

  console.log('  Created 4 jobs (3 published, 1 draft)')

  // ─── Applications ──────────────────────────────────────────────
  await prisma.application.createMany({
    data: [
      {
        jobId: job1.id,
        workerId: worker1.id,
        status: 'accepted',
        coverNote: 'I have extensive warehouse experience and am forklift certified. Available to start immediately.',
        proposedRate: 20,
      },
      {
        jobId: job1.id,
        workerId: worker2.id,
        status: 'pending',
        coverNote: 'Interested in warehouse work. Quick learner and available full-time.',
        proposedRate: 17,
      },
      {
        jobId: job2.id,
        workerId: worker2.id,
        status: 'shortlisted',
        coverNote: 'I have 3 years of event experience and love working with people.',
        proposedRate: 18,
      },
      {
        jobId: job3.id,
        workerId: worker3.id,
        status: 'pending',
        coverNote: 'Data entry is my specialty. Very detail-oriented with fast typing speed.',
        proposedRate: 19,
      },
    ],
  })

  console.log('  Created 4 applications')

  // ─── Shifts ────────────────────────────────────────────────────
  const today = new Date()
  const tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)
  const nextWeek = new Date(today)
  nextWeek.setDate(nextWeek.getDate() + 7)

  await prisma.shift.createMany({
    data: [
      {
        jobId: job1.id,
        workerId: worker1.id,
        date: tomorrow,
        startTime: '08:00',
        endTime: '16:00',
        status: 'scheduled',
        hourlyRate: 20,
      },
      {
        jobId: job1.id,
        workerId: worker1.id,
        date: nextWeek,
        startTime: '08:00',
        endTime: '16:00',
        status: 'scheduled',
        hourlyRate: 20,
      },
      {
        jobId: job1.id,
        workerId: worker1.id,
        date: new Date(today.getFullYear(), today.getMonth(), today.getDate() - 2),
        startTime: '08:00',
        endTime: '16:30',
        status: 'completed',
        clockInTime: new Date(today.getFullYear(), today.getMonth(), today.getDate() - 2, 7, 58),
        clockOutTime: new Date(today.getFullYear(), today.getMonth(), today.getDate() - 2, 16, 32),
        breakMinutes: 30,
        totalHours: 8.07,
        hourlyRate: 20,
        totalPay: 161.4,
      },
    ],
  })

  console.log('  Created 3 shifts (1 completed, 2 scheduled)')

  // ─── Reviews ───────────────────────────────────────────────────
  await prisma.review.create({
    data: {
      reviewerId: employer1.id,
      revieweeId: worker1.id,
      jobId: job1.id,
      rating: 5,
      comment: 'Anna is an excellent worker. Very reliable and efficient. Would hire again!',
    },
  })

  console.log('  Created 1 review')

  // ─── Notifications ─────────────────────────────────────────────
  await prisma.notification.createMany({
    data: [
      {
        userId: worker1.id,
        type: 'shift_reminder',
        title: 'Shift Tomorrow',
        body: 'You have a shift at LogiCorp Oy tomorrow at 08:00',
        data: JSON.stringify({ shiftId: 'placeholder', jobTitle: 'Warehouse Associate' }),
        isRead: false,
      },
      {
        userId: worker2.id,
        type: 'application_status_changed',
        title: 'Application Update',
        body: 'Your application for "Event Staff — Corporate Gala" has been shortlisted!',
        data: JSON.stringify({ applicationId: 'placeholder', jobTitle: 'Event Staff — Corporate Gala' }),
        isRead: false,
      },
      {
        userId: employer1.id,
        type: 'application_received',
        title: 'New Application',
        body: 'Mikko Mäkinen applied for "Warehouse Associate — Peak Season"',
        data: JSON.stringify({ applicantName: 'Mikko Mäkinen' }),
        isRead: true,
      },
    ],
  })

  console.log('  Created 3 notifications')

  // ─── Summary ───────────────────────────────────────────────────
  const counts = {
    users: await prisma.user.count(),
    profiles: await prisma.workerProfile.count(),
    companies: await prisma.company.count(),
    jobs: await prisma.job.count(),
    applications: await prisma.application.count(),
    shifts: await prisma.shift.count(),
    reviews: await prisma.review.count(),
    notifications: await prisma.notification.count(),
  }

  console.log('\n✅ Seed complete!')
  console.log('   Summary:', JSON.stringify(counts, null, 2))
  console.log('\n📋 Test Accounts:')
  console.log('   Admin:    admin@__SLUG__.com      / Admin123!')
  console.log('   Employer: maria@logicorp.fi        / Employer123!')
  console.log('   Employer: erik@eventpro.fi         / Employer123!')
  console.log('   Worker:   anna@example.com         / Worker123!')
  console.log('   Worker:   mikko@example.com        / Worker123!')
  console.log('   Worker:   sofia@example.com        / Worker123!')
}

main()
  .catch((e) => {
    console.error('Seed failed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
