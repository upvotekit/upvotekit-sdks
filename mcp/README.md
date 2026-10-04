# @upvotekit/mcp

First-party [Model Context Protocol](https://modelcontextprotocol.io) server for UpvoteKit. It is a **thin stdio client over the public REST API** (`/api/v1`) — it never talks to the database or imports app server code.

## Why scoped keys

Competitor MCP integrations often use all-powerful admin keys. UpvoteKit MCP authenticates with the same **scoped API keys** as the Developer API (`Authorization: Bearer upk_live_…`). Give an agent a `feedback:read`-only key and write tools fail with a clear “Missing required scope” message. Match the key to the job.

## Environment

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `UPVOTEKIT_API_KEY` | yes | — | Project API key (`upk_live_…`) |
| `UPVOTEKIT_BASE_URL` | no | `https://upvotekit.com` | API origin (no trailing slash) |

The process exits immediately if `UPVOTEKIT_API_KEY` is missing.

## Install / run

Requires Node.js 20+.

```bash
UPVOTEKIT_API_KEY=upk_live_… npx -y @upvotekit/mcp
```

Binary name: `upvotekit-mcp` (points at `dist/index.js`).

## Cursor

User config (`~/.cursor/mcp.json`) or project (`.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "upvotekit": {
      "command": "npx",
      "args": ["-y", "@upvotekit/mcp"],
      "env": {
        "UPVOTEKIT_API_KEY": "upk_live_…"
      }
    }
  }
}
```

Use a read-only key for exploratory agents; a broader key only when the agent must mutate.

## Claude Desktop

In Claude Desktop → Settings → Developer → Edit Config, add:

```json
{
  "mcpServers": {
    "upvotekit": {
      "command": "npx",
      "args": ["-y", "@upvotekit/mcp"],
      "env": {
        "UPVOTEKIT_API_KEY": "upk_live_…"
      }
    }
  }
}
```

Restart Claude Desktop after saving.

## Tools

| Tool | Scope | Notes |
| --- | --- | --- |
| `list_feedback` | `feedback:read` | Filters: `q`, `board_id`, `status_id`, `tag_id`, `sort`, `min_votes`, `limit` |
| `get_feedback` | `feedback:read` | |
| `create_feedback` | `feedback:write` | **Mutating** |
| `update_feedback` | `feedback:write` | **Mutating** — status, tags, ETA, priority, title/description, … |
| `preview_merge_feedback` | `feedback:moderate` | Read-only preview |
| `merge_feedback` | `feedback:moderate` | **Destructive** |
| `list_comments` | `comments:read` | |
| `add_comment` | `comments:write` | **Mutating** — API keys must supply an author |
| `list_boards` | `project:read` | |
| `list_statuses` | `project:read` | |
| `list_tags` | `project:read` | |
| `get_roadmap` | `roadmap:read` | |
| `list_releases` | `releases:read` | |
| `create_release_draft` | `releases:write` | **Mutating** |
| `publish_release` | `releases:write` | **Destructive** |
| `analytics_summary` | `analytics:read` | |

Delete/purge endpoints are intentionally not exposed.

Tool arguments use **snake_case**. Some PATCH/POST bodies are mapped to the API’s camelCase fields where the server Zod schemas require it.

## Develop locally

```bash
cd sdk/mcp
bun install
UPVOTEKIT_API_KEY=upk_live_… UPVOTEKIT_BASE_URL=http://localhost:3100 bun run src/index.ts
bun run build
```

With the API running locally, pass a full-scope key and a `feedback:read`-only key of the same project (it writes
one comment each run):

```bash
UPVOTEKIT_SMOKE_KEY=upk_live_… UPVOTEKIT_SMOKE_READ_ONLY_KEY=upk_live_… bun run smoke
```

## Layout

```
src/index.ts          entry (stdio)
src/config.ts         env
src/api-client.ts     fetch + error envelope
src/format.ts         compact tool output
src/tools/*.ts        one module per resource group
scripts/smoke.ts      stdio client smoke
dist/index.js         build output (Node)
```
