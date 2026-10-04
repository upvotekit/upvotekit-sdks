#!/usr/bin/env node
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { ApiClient } from './api-client.ts'
import { loadConfig } from './config.ts'
import { registerAllTools } from './tools/index.ts'
import { version } from '../package.json' with { type: 'json' }

async function main() {
  const config = loadConfig()
  const api = new ApiClient(config)

  const server = new McpServer({
    name: 'upvotekit',
    version,
  })

  registerAllTools(server, api)

  const transport = new StdioServerTransport()
  await server.connect(transport)
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err)
  process.exit(1)
})
