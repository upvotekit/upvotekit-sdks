import type { RegisterTools } from './helpers.ts'
import { runTool } from './helpers.ts'

export const registerRoadmapTools: RegisterTools = (server, api) => {
  server.registerTool(
    'get_roadmap',
    {
      description:
        'Get the public roadmap: status columns with ordered feedback cards. Requires roadmap:read.',
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async () => runTool(async () => api.get('/api/v1/roadmap'), {}),
  )
}
