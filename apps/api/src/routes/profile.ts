import { Router, type IRouter } from 'express'

export const profileRouter: IRouter = Router()

profileRouter.get('/', async (_req, res) => {
  res.json({ success: true, data: { message: 'Profile endpoint' } })
})

profileRouter.patch('/', async (_req, res) => {
  res.json({ success: true, data: { message: 'Update profile endpoint' } })
})
