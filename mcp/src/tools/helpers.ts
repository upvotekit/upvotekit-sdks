import type { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { ApiError, type ApiClient } from '../api-client.ts'
import { errorContent, formatResult, textContent } from '../format.ts'

type ToolHandler = (args: Record<string, unknown>) => Promise<unknown>

/** Run a tool handler and map ApiError / unexpected errors into MCP tool results. */
export async function runTool(handler: ToolHandler, args: Record<string, unknown>) {
  try {
    const data = await handler(args)
    return textContent(formatResult(data))
  } catch (err) {
    if (err instanceof ApiError) return errorContent(err.toToolMessage())
    const message = err instanceof Error ? err.message : String(err)
    return errorContent(message)
  }
}

export type RegisterTools = (server: McpServer, api: ApiClient) => void
