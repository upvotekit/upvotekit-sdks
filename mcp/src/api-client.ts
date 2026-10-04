import type { McpConfig } from './config.ts'

export class ApiError extends Error {
  readonly status: number
  readonly code: string | undefined
  readonly requestId: string | undefined
  readonly details: unknown
  readonly missingScope: string | undefined

  constructor(opts: {
    status: number
    message: string
    code?: string
    requestId?: string
    details?: unknown
    missingScope?: string
  }) {
    super(opts.message)
    this.name = 'ApiError'
    this.status = opts.status
    this.code = opts.code
    this.requestId = opts.requestId
    this.details = opts.details
    this.missingScope = opts.missingScope
  }

  /** Human-readable message for MCP tool errors. */
  toToolMessage(): string {
    const parts = [`API ${this.status}`]
    if (this.code) parts.push(`(${this.code})`)
    parts.push(`: ${this.message}`)
    if (this.missingScope && !/Missing required scope/i.test(this.message)) {
      parts.push(` Required scope: ${this.missingScope}. Use an API key that includes this scope.`)
    } else if (this.missingScope) {
      parts.push(` Use an API key that includes this scope.`)
    }
    if (this.requestId) parts.push(` request_id=${this.requestId}`)
    return parts.join('')
  }
}

type Query = Record<string, string | number | boolean | undefined | null>

export class ApiClient {
  constructor(private readonly config: McpConfig) {}

  get<T = unknown>(path: string, query?: Query): Promise<T> {
    return this.request<T>('GET', path, { query })
  }

  post<T = unknown>(path: string, body?: unknown): Promise<T> {
    return this.request<T>('POST', path, { body })
  }

  patch<T = unknown>(path: string, body?: unknown): Promise<T> {
    return this.request<T>('PATCH', path, { body })
  }

  private async request<T>(
    method: string,
    path: string,
    opts: { query?: Query; body?: unknown } = {},
  ): Promise<T> {
    // Always relative to baseUrl so the API key is never sent to another host.
    const url = new URL(`${this.config.baseUrl}/${path.replace(/^\/+/, '')}`)
    if (opts.query) {
      for (const [key, value] of Object.entries(opts.query)) {
        if (value === undefined || value === null || value === '') continue
        url.searchParams.set(key, String(value))
      }
    }

    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.config.apiKey}`,
      Accept: 'application/json',
    }
    let body: string | undefined
    if (opts.body !== undefined) {
      headers['Content-Type'] = 'application/json'
      body = JSON.stringify(opts.body)
    }

    const res = await fetch(url, { method, headers, body })
    const text = await res.text()
    let json: unknown
    try {
      json = text ? JSON.parse(text) : null
    } catch {
      throw new ApiError({
        status: res.status,
        message: text || res.statusText || 'Non-JSON response',
      })
    }

    if (!res.ok) throw this.toApiError(res.status, json)
    return json as T
  }

  private toApiError(status: number, json: unknown): ApiError {
    const envelope = json as {
      error?: { code?: string; message?: string; details?: unknown }
      request_id?: string
    } | null

    const code = envelope?.error?.code
    let message = envelope?.error?.message || `Request failed with status ${status}`
    const requestId = envelope?.request_id
    const details = envelope?.error?.details
    if (details != null && !envelope?.error?.message) {
      message = `${message} ${JSON.stringify(details)}`
    } else if (details != null && typeof details === 'object') {
      // Include validation / server details when present.
      message = `${message} ${JSON.stringify(details)}`
    }

    const scopeMatch = message.match(/Missing required scope:\s*([a-z0-9_:{}/-]+)/i)
    const missingScope = scopeMatch?.[1]

    return new ApiError({ status, code, message, requestId, details, missingScope })
  }
}
