## 0.1.0

* Initial MCP server over the UpvoteKit REST API (`/api/v1`), authenticated with a scoped project API key.
* 16 tools for feedback, comments, boards, statuses, tags, roadmap, releases and analytics. No delete or purge tools.
* Runs on Node 20+ (`npx -y @upvotekit/mcp`). Defaults to `https://upvotekit.com`; set `UPVOTEKIT_BASE_URL` for a
  self-hosted or local server.
