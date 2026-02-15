import express, { type Express } from 'express'
import cors from 'cors'
import helmet from 'helmet'
import compression from 'compression'
import { API_VERSION } from '__SCOPE__/shared'
import { authRouter } from './routes/auth.js'
import { jobsRouter } from './routes/jobs.js'
import { shiftsRouter } from './routes/shifts.js'
import { profileRouter } from './routes/profile.js'
import { errorHandler } from './middleware/errorHandler.js'
import { requestLogger } from './middleware/requestLogger.js'

const app: Express = express()
const PORT = process.env.PORT || 3001

// Global middleware
app.use(helmet())
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'] }))
app.use(compression())
app.use(express.json({ limit: '10mb' }))
app.use(requestLogger)

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', version: API_VERSION, timestamp: new Date().toISOString() })
})

// API routes
const apiPrefix = `/api/${API_VERSION}`
app.use(`${apiPrefix}/auth`, authRouter)
app.use(`${apiPrefix}/jobs`, jobsRouter)
app.use(`${apiPrefix}/shifts`, shiftsRouter)
app.use(`${apiPrefix}/profile`, profileRouter)

// Error handling (must be last)
app.use(errorHandler)

app.listen(PORT, () => {
  console.log(`[API] Server running on http://localhost:${PORT}`)
  console.log(`[API] API prefix: ${apiPrefix}`)
})

export default app
