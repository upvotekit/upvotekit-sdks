import { z } from 'zod'
import type { RegisterTools } from './helpers.ts'
import { runTool } from './helpers.ts'

const sortEnum = z.enum(['top', 'new', 'updated', 'oldest', 'comments', 'priority', 'revenue'])

export const registerFeedbackTools: RegisterTools = (server, api) => {
  server.registerTool(
    'list_feedback',
    {
      description:
        'List or search feature requests on the board. Supports text search (q), board/status/tag filters, sort, min_votes, and limit. Requires feedback:read.',
      inputSchema: {
        q: z.string().max(200).optional().describe('Full-text search over title/description'),
        board_id: z.string().optional().describe('Filter by board id'),
        status_id: z.string().optional().describe('Filter by status id'),
        tag_id: z.string().optional().describe('Filter by tag id'),
        sort: sortEnum.optional().describe('Sort order (default: new)'),
        min_votes: z.number().int().min(0).optional().describe('Minimum vote count'),
        limit: z.number().int().min(1).max(100).optional().describe('Page size (1–100, default 25)'),
        offset: z.number().int().min(0).optional().describe('Pagination offset'),
      },
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(async () => {
        return api.get('/api/v1/feedback', {
          q: args.q,
          board_id: args.board_id,
          status_id: args.status_id,
          tag_id: args.tag_id,
          sort: args.sort,
          min_votes: args.min_votes,
          limit: args.limit,
          offset: args.offset,
        })
      }, args),
  )

  server.registerTool(
    'get_feedback',
    {
      description: 'Get a single feedback item by id, including status, tags, votes, and author. Requires feedback:read.',
      inputSchema: {
        id: z.string().describe('Feedback id'),
      },
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(async () => api.get(`/api/v1/feedback/${encodeURIComponent(args.id)}`), args),
  )

  server.registerTool(
    'create_feedback',
    {
      description:
        'MUTATING: Create a new feedback item (feature request). Optionally set board_id, description, tag_ids, and author. Requires feedback:write.',
      inputSchema: {
        title: z.string().min(3).max(200).describe('Title (3–200 chars)'),
        description: z.string().max(10000).nullable().optional().describe('Optional body'),
        board_id: z.string().optional().describe('Board id (defaults to first board)'),
        tag_ids: z.array(z.string()).max(20).optional().describe('Tag ids to attach'),
        author_external_user_id: z.string().max(191).optional().describe('Author external_user_id (optional)'),
        author_email: z.string().email().optional().describe('Author email (optional)'),
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
        return api.post('/api/v1/feedback', {
          title: args.title,
          description: args.description,
          board_id: args.board_id,
          tag_ids: args.tag_ids,
          author,
        })
      }, args),
  )

  server.registerTool(
    'update_feedback',
    {
      description:
        'MUTATING: Update a feedback item — title, description, status, tags, target period (ETA), priority, board, moderation, visibility, or comments lock. Requires feedback:write. Send only fields you want to change.',
      inputSchema: {
        id: z.string().describe('Feedback id'),
        title: z.string().min(3).max(200).optional(),
        description: z.string().max(10000).nullable().optional(),
        board_id: z.string().optional(),
        status_id: z.string().optional().describe('New status id'),
        tag_ids: z.array(z.string()).max(20).optional().describe('Replace tag set'),
        target_period: z.string().max(40).nullable().optional().describe('ETA label, e.g. "Q2 2026"'),
        priority: z.number().int().min(0).max(100).nullable().optional(),
        moderation_state: z.enum(['pending', 'approved', 'rejected']).optional(),
        public_visibility: z.boolean().optional(),
        comments_locked: z.boolean().optional(),
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true },
    },
    async (args) =>
      runTool(async () => {
        // PATCH body uses camelCase field names (API Zod schema).
        const body: Record<string, unknown> = {}
        if (args.title !== undefined) body.title = args.title
        if (args.description !== undefined) body.description = args.description
        if (args.board_id !== undefined) body.boardId = args.board_id
        if (args.status_id !== undefined) body.statusId = args.status_id
        if (args.tag_ids !== undefined) body.tagIds = args.tag_ids
        if (args.target_period !== undefined) body.targetPeriod = args.target_period
        if (args.priority !== undefined) body.priority = args.priority
        if (args.moderation_state !== undefined) body.moderationState = args.moderation_state
        if (args.public_visibility !== undefined) body.publicVisibility = args.public_visibility
        if (args.comments_locked !== undefined) body.commentsLocked = args.comments_locked
        return api.patch(`/api/v1/feedback/${encodeURIComponent(args.id)}`, body)
      }, args),
  )

  server.registerTool(
    'preview_merge_feedback',
    {
      description:
        'Preview merging source feedback into a target (vote/comment transfer plan). Does not modify data. Requires feedback:moderate.',
      inputSchema: {
        id: z.string().describe('Source feedback id (will be merged away)'),
        target_id: z.string().describe('Target feedback id (survivor)'),
      },
      annotations: { readOnlyHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(
        async () =>
          api.get(`/api/v1/feedback/${encodeURIComponent(args.id)}/merge`, {
            target_id: args.target_id,
          }),
        args,
      ),
  )

  server.registerTool(
    'merge_feedback',
    {
      description:
        'DESTRUCTIVE: Permanently merge source feedback into target_id (moves votes/comments, marks source merged). Preview first with preview_merge_feedback. Requires feedback:moderate.',
      inputSchema: {
        id: z.string().describe('Source feedback id (merged away)'),
        target_id: z.string().describe('Target feedback id (survivor)'),
      },
      annotations: { readOnlyHint: false, destructiveHint: true, openWorldHint: true },
    },
    async (args) =>
      runTool(
        async () =>
          api.post(`/api/v1/feedback/${encodeURIComponent(args.id)}/merge`, {
            target_id: args.target_id,
          }),
        args,
      ),
  )
}
