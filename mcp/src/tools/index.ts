import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import type { ApiClient } from '../api-client.ts'
import { registerAnalyticsTools } from './analytics.ts'
import { registerCommentTools } from './comments.ts'
import { registerFeedbackTools } from './feedback.ts'
import { registerReleaseTools } from './releases.ts'
import { registerRoadmapTools } from './roadmap.ts'
import { registerStatusesTagsTools } from './statuses-tags.ts'

export function registerAllTools(server: McpServer, api: ApiClient) {
  registerFeedbackTools(server, api)
  registerCommentTools(server, api)
  registerStatusesTagsTools(server, api)
  registerRoadmapTools(server, api)
  registerReleaseTools(server, api)
  registerAnalyticsTools(server, api)
}
