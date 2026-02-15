import { Router } from 'express'
import { CreateJobSchema } from '__SCOPE__/shared'
import { calculateMatchScore } from '__SCOPE__/business-logic'

export const jobsRouter = Router()

jobsRouter.get('/', async (req, res, next) => {
  try {
    // TODO: Implement with Prisma + filters from query params
    res.json({
      success: true,
      data: [],
      pagination: { page: 1, pageSize: 20, total: 0, totalPages: 0, hasNext: false, hasPrev: false },
    })
  } catch (error) {
    next(error)
  }
})

jobsRouter.get('/:id', async (req, res, next) => {
  try {
    // TODO: Fetch job by ID from Prisma
    res.json({ success: true, data: { id: req.params.id } })
  } catch (error) {
    next(error)
  }
})

jobsRouter.post('/', async (req, res, next) => {
  try {
    const data = CreateJobSchema.parse(req.body)
    // TODO: Create job with Prisma
    res.status(201).json({ success: true, data })
  } catch (error) {
    next(error)
  }
})

jobsRouter.patch('/:id', async (req, res, next) => {
  try {
    // TODO: Update job with Prisma
    res.json({ success: true, data: { id: req.params.id } })
  } catch (error) {
    next(error)
  }
})

jobsRouter.delete('/:id', async (req, res, next) => {
  try {
    // TODO: Delete job with Prisma
    res.json({ success: true, data: { id: req.params.id } })
  } catch (error) {
    next(error)
  }
})

jobsRouter.post('/:id/apply', async (req, res, next) => {
  try {
    // TODO: Create application with Prisma
    res.status(201).json({ success: true, data: { jobId: req.params.id } })
  } catch (error) {
    next(error)
  }
})

jobsRouter.get('/:id/applications', async (req, res, next) => {
  try {
    // TODO: Fetch applications for this job
    res.json({
      success: true,
      data: [],
      pagination: { page: 1, pageSize: 20, total: 0, totalPages: 0, hasNext: false, hasPrev: false },
    })
  } catch (error) {
    next(error)
  }
})
