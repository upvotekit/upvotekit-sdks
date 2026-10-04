export type McpConfig = {
  apiKey: string
  baseUrl: string
}

/** Load MCP config from env. Fails fast if the API key is missing. */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): McpConfig {
  const apiKey = env.UPVOTEKIT_API_KEY?.trim()
  if (!apiKey) {
    throw new Error(
      'UPVOTEKIT_API_KEY is required. Set it to a project API key (upk_live_...). Scope the key to limit what the agent can do.',
    )
  }

  const baseUrl = (env.UPVOTEKIT_BASE_URL?.trim() || 'https://upvotekit.com').replace(/\/+$/, '')
  return { apiKey, baseUrl }
}
