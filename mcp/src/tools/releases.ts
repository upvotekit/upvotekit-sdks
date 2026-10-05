import { z } from 'zod'
import type { RegisterTools } from './helpers.ts'
import { runTool } from './helpers.ts'

export const registerReleaseTools: RegisterTools = (server, api) => {
  server.registerTool(
    'list_releases',
    {
      description:
        'List changelog releases (drafts and/or published). state=published for public only, state=all (default) for drafts too. Requires releases:read.',
      inputSchema: {
        state: z.enum(['published', 'all']).optional().describe('Filter by publish state'),
        limit: z.number().int().min(1).max(100).optional(),
        offset: z.number().int().min(0).optional(),
      },
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(
        async () =>
          api.get('/api/v1/releases', {
            state: args.state,
            limit: args.limit,
            offset: args.offset,
          }),
        args,
      ),
  )

  server.registerTool(
    'create_release_draft',
    {
      description:
        'MUTATING: Create a draft release (changelog entry). Optionally link feedback_ids. Does not publish. Requires releases:write.',
      inputSchema: {
        title: z.string().min(2).max(200).describe('Release title'),
        version: z.string().max(40).nullable().optional().describe('Version label, e.g. v2.5'),
        summary: z.string().max(1000).nullable().optional().describe('Short summary'),
        body_markdown: z.string().max(50000).nullable().optional().describe('Markdown body'),
        feedback_ids: z.array(z.string()).max(200).optional().describe('Linked feedback ids'),
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true },
    },
    async (args) =>
      runTool(async () => {
        // Release create body uses camelCase (API Zod schema).
        return api.post('/api/v1/releases', {
          title: args.title,
          version: args.version,
          summary: args.summary,
          bodyMarkdown: args.body_markdown,
          feedbackIds: args.feedback_ids,
        })
      }, args),
  )

  server.registerTool(
    'publish_release',
    {
      description:
        'DESTRUCTIVE: Publish a draft release (makes it public on the changelog and emails people). Optionally mark linked feedback as Completed. Requires releases:write.',
      inputSchema: {
        id: z.string().describe('Release id'),
        mark_linked_completed: z
          .boolean()
          .optional()
          .describe('If true, mark linked feedback Completed when publishing'),
        email_subscribers: z
          .boolean()
          .optional()
          .describe("Also email the changelog's subscribers (default true). Followers of linked feedback are emailed either way"),
      },
      annotations: { readOnlyHint: false, destructiveHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(
        async () =>
          api.post(`/api/v1/releases/${encodeURIComponent(args.id)}/publish`, {
            mark_linked_completed: args.mark_linked_completed ?? false,
            email_subscribers: args.email_subscribers,
          }),
        args,
      ),
  )
}
