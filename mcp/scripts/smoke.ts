/**
 * Smoke-test the MCP server over stdio: list tools, call a few read tools with a full key,
 * and confirm a write with the read-only key is rejected with a helpful scope message.
 *
 * Usage: UPVOTEKIT_SMOKE_KEY=upk_live_… UPVOTEKIT_SMOKE_READ_ONLY_KEY=upk_live_… bun run scripts/smoke.ts
 * Expects the UpvoteKit API at UPVOTEKIT_BASE_URL (default http://localhost:3100). The keys belong to one project:
 * a full-scope key and a `feedback:read`-only key.
 */
import { Client } from '@modelcontextprotocol/sdk/client/index.js'
import { StdioClientTransport, getDefaultEnvironment } from '@modelcontextprotocol/sdk/client/stdio.js'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const FULL_KEY = requiredEnv('UPVOTEKIT_SMOKE_KEY')
const READ_ONLY_KEY = requiredEnv('UPVOTEKIT_SMOKE_READ_ONLY_KEY')
const BASE_URL = process.env.UPVOTEKIT_BASE_URL?.trim() || 'http://localhost:3100'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const serverEntry = join(root, 'src/index.ts')

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim()
  if (!value) throw new Error(`${name} is required`)
  return value
}

type ToolResult = {
  isError?: boolean
  content?: Array<{ type: string; text?: string }>
}

function textOf(result: ToolResult): string {
  return (result.content ?? []).map((c) => c.text ?? '').join('\n')
}

async function withClient(apiKey: string, fn: (client: Client) => Promise<void>) {
  const transport = new StdioClientTransport({
    command: process.execPath.includes('bun') ? process.execPath : 'bun',
    args: [serverEntry],
    cwd: root,
    env: {
      ...getDefaultEnvironment(),
      UPVOTEKIT_API_KEY: apiKey,
      UPVOTEKIT_BASE_URL: BASE_URL,
    },
    stderr: 'inherit',
  })

  const client = new Client({ name: 'upvotekit-mcp-smoke', version: '0.1.0' })
  try {
    await client.connect(transport)
    await fn(client)
  } finally {
    await client.close().catch(() => {})
  }
}

function assert(cond: unknown, message: string): asserts cond {
  if (!cond) throw new Error(message)
}

async function main() {
  console.log('Smoke: listing tools + read calls with full key…')
  let sampleFeedbackId: string | undefined
  let createdCommentId: string | undefined

  await withClient(FULL_KEY, async (client) => {
    const { tools } = await client.listTools()
    console.log(`  tools (${tools.length}): ${tools.map((t) => t.name).sort().join(', ')}`)
    assert(tools.length >= 15, `expected >= 15 tools, got ${tools.length}`)

    const boards = (await client.callTool({ name: 'list_boards', arguments: {} })) as ToolResult
    assert(!boards.isError, `list_boards failed: ${textOf(boards)}`)
    console.log('  list_boards: ok')

    const list = (await client.callTool({
      name: 'list_feedback',
      arguments: { sort: 'top', limit: 3 },
    })) as ToolResult
    assert(!list.isError, `list_feedback failed: ${textOf(list)}`)
    const listJson = JSON.parse(textOf(list)) as { data?: Array<{ id: string }> }
    sampleFeedbackId = listJson.data?.[0]?.id
    assert(sampleFeedbackId, 'list_feedback returned no items')
    console.log(`  list_feedback: ok (sample id=${sampleFeedbackId})`)

    const one = (await client.callTool({
      name: 'get_feedback',
      arguments: { id: sampleFeedbackId },
    })) as ToolResult
    assert(!one.isError, `get_feedback failed: ${textOf(one)}`)
    console.log('  get_feedback: ok')

    const statuses = (await client.callTool({ name: 'list_statuses', arguments: {} })) as ToolResult
    assert(!statuses.isError, `list_statuses failed: ${textOf(statuses)}`)
    console.log('  list_statuses: ok')

    // One small write so we exercise comments:write (minimal junk).
    const comment = (await client.callTool({
      name: 'add_comment',
      arguments: {
        feedback_id: sampleFeedbackId,
        body: 'MCP smoke test comment — safe to ignore',
        author_external_user_id: 'mcp-smoke',
        author_email: 'mcp-smoke@upvotekit.local',
        author_display_name: 'MCP Smoke',
      },
    })) as ToolResult
    assert(!comment.isError, `add_comment failed: ${textOf(comment)}`)
    const commentJson = JSON.parse(textOf(comment)) as { data?: { id?: string } }
    createdCommentId = commentJson.data?.id
    console.log(`  add_comment: ok (id=${createdCommentId ?? 'unknown'})`)
  })

  console.log('Smoke: write with read-only key should fail with missing scope…')
  await withClient(READ_ONLY_KEY, async (client) => {
    const result = (await client.callTool({
      name: 'create_feedback',
      arguments: { title: 'Should be rejected by read-only key' },
    })) as ToolResult
    assert(result.isError, 'expected create_feedback to fail with read-only key')
    const msg = textOf(result)
    assert(/feedback:write/i.test(msg), `expected missing-scope message mentioning feedback:write, got: ${msg}`)
    console.log(`  create_feedback (read-only): rejected as expected`)
    console.log(`    ${msg}`)
  })

  console.log('\nSmoke passed.')
  if (createdCommentId) {
    console.log(`Created test comment id: ${createdCommentId} (on feedback ${sampleFeedbackId})`)
  }
}

main().catch((err) => {
  console.error('Smoke FAILED:', err instanceof Error ? err.message : err)
  process.exit(1)
})
