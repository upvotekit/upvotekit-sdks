import { z } from 'zod'
import type { RegisterTools } from './helpers.ts'
import { runTool } from './helpers.ts'

export const registerAnalyticsTools: RegisterTools = (server, api) => {
  server.registerTool(
    'analytics_summary',
    {
      description:
        'Project analytics summary for the last N days (votes, feedback created, comments, etc.). Requires analytics:read.',
      inputSchema: {
        days: z.number().int().min(1).max(365).optional().describe('Lookback window (default 30)'),
      },
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(async () => api.get('/api/v1/analytics', { days: args.days }), args),
  )
}
