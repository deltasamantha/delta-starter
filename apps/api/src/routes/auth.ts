import { Router, type IRouter } from 'express'
import { RegisterSchema, LoginSchema } from '__SCOPE__/shared'

export const authRouter: IRouter = Router()

authRouter.post('/register', async (req, res, next) => {
  try {
    const data = RegisterSchema.parse(req.body)
    // TODO: Implement registration with Prisma
    res.status(201).json({
      success: true,
      data: { message: 'Registration endpoint — implement with Prisma' },
    })
  } catch (error) {
    next(error)
  }
})

authRouter.post('/login', async (req, res, next) => {
  try {
    const data = LoginSchema.parse(req.body)
    // TODO: Implement login
    res.json({
      success: true,
      data: { message: 'Login endpoint — implement with Prisma + JWT' },
    })
  } catch (error) {
    next(error)
  }
})

authRouter.post('/logout', async (_req, res) => {
  res.json({ success: true, data: { message: 'Logged out' } })
})

authRouter.get('/me', async (_req, res) => {
  // TODO: Extract user from JWT
  res.json({ success: true, data: { message: 'Current user endpoint' } })
})
