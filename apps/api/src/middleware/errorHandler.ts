import type { Request, Response, NextFunction } from 'express'
import { ZodError } from 'zod'
import type { ApiErrorResponse } from '__SCOPE__/shared'

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction) {
  console.error('[API Error]', err)

  // Zod validation errors
  if (err instanceof ZodError) {
    const details: Record<string, string[]> = {}
    err.errors.forEach((e) => {
      const path = e.path.join('.')
      if (!details[path]) details[path] = []
      details[path].push(e.message)
    })

    const response: ApiErrorResponse = {
      success: false,
      error: 'Validation failed',
      details,
      statusCode: 400,
    }
    return res.status(400).json(response)
  }

  // Generic errors
  const statusCode = (err as any).statusCode || 500
  const response: ApiErrorResponse = {
    success: false,
    error: statusCode === 500 ? 'Internal server error' : err.message,
    statusCode,
  }

  res.status(statusCode).json(response)
}
