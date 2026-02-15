import { Router, type IRouter } from 'express'

export const shiftsRouter: IRouter = Router()

shiftsRouter.get('/', async (_req, res) => {
  res.json({ success: true, data: [], pagination: { page: 1, pageSize: 20, total: 0, totalPages: 0, hasNext: false, hasPrev: false } })
})

shiftsRouter.post('/:id/clock-in', async (req, res) => {
  res.json({ success: true, data: { shiftId: req.params.id, clockInTime: new Date() } })
})

shiftsRouter.post('/:id/clock-out', async (req, res) => {
  res.json({ success: true, data: { shiftId: req.params.id, clockOutTime: new Date() } })
})
