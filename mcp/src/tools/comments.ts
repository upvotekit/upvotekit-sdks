import { z } from 'zod'
import type { RegisterTools } from './helpers.ts'
import { runTool } from './helpers.ts'

export const registerCommentTools: RegisterTools = (server, api) => {
  server.registerTool(
    'list_comments',
    {
      description: 'List comments on a feedback item. Requires comments:read.',
      inputSchema: {
        feedback_id: z.string().describe('Feedback id'),
      },
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(
        async () => api.get(`/api/v1/feedback/${encodeURIComponent(args.feedback_id)}/comments`),
        args,
      ),
  )

  server.registerTool(
    'add_comment',
    {
      description:
        'MUTATING: Add a comment to a feedback item. When using an API key, author (external_user_id and/or email) is required. Requires comments:write.',
      inputSchema: {
        feedback_id: z.string().describe('Feedback id'),
        body: z.string().min(1).max(5000).describe('Comment text'),
        parent_comment_id: z.string().optional().describe('Reply-to comment id'),
        author_external_user_id: z.string().max(191).optional().describe('Author external_user_id'),
        author_email: z.string().email().optional().describe('Author email'),
        author_display_name: z.string().max(120).optional().describe('Author display name'),
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true },
    },
    async (args) =>
      runTool(async () => {
        const author =
          args.author_external_user_id || args.author_email
            ? {
                external_user_id: args.author_external_user_id,
                email: args.author_email,
                display_name: args.author_display_name,
              }
            : undefined
        return api.post(`/api/v1/feedback/${encodeURIComponent(args.feedback_id)}/comments`, {
          body: args.body,
          parent_comment_id: args.parent_comment_id,
          author,
        })
      }, args),
  )
}
