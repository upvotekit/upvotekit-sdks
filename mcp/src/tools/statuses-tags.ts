import type { RegisterTools } from './helpers.ts'
import { runTool } from './helpers.ts'

export const registerStatusesTagsTools: RegisterTools = (server, api) => {
  server.registerTool(
    'list_boards',
    {
      description: 'List boards in the project (ids, names, slugs, submission/voting modes). Requires project:read.',
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async () => runTool(async () => api.get('/api/v1/boards'), {}),
  )

  server.registerTool(
    'list_statuses',
    {
      description: 'List feedback statuses (Under Review, Planned, In Progress, Completed, …). Requires project:read.',
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async () => runTool(async () => api.get('/api/v1/statuses'), {}),
  )

  server.registerTool(
    'list_tags',
    {
      description: 'List project tags usable when creating/updating feedback. Requires project:read.',
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async () => runTool(async () => api.get('/api/v1/tags'), {}),
  )
}
