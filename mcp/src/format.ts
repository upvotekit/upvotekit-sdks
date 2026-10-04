const MAX_STRING = 400
const OMIT_KEYS = new Set(['bodyHtml', 'body_html'])

/** Compact JSON for tool results — omit huge HTML, truncate long strings. */
export function formatResult(value: unknown, maxDepth = 8): string {
  return JSON.stringify(trimValue(value, maxDepth), null, 2)
}

function trimValue(value: unknown, depth: number): unknown {
  if (depth <= 0) return '[truncated]'
  if (value == null) return value
  if (typeof value === 'string') {
    if (value.length <= MAX_STRING) return value
    return `${value.slice(0, MAX_STRING)}… (+${value.length - MAX_STRING} chars)`
  }
  if (Array.isArray(value)) return value.map((item) => trimValue(item, depth - 1))
  if (typeof value === 'object') {
    const out: Record<string, unknown> = {}
    for (const [key, child] of Object.entries(value as Record<string, unknown>)) {
      if (OMIT_KEYS.has(key)) continue
      out[key] = trimValue(child, depth - 1)
    }
    return out
  }
  return value
}

export function textContent(text: string): { content: [{ type: 'text'; text: string }] } {
  return { content: [{ type: 'text', text }] }
}

export function errorContent(message: string): {
  isError: true
  content: [{ type: 'text'; text: string }]
} {
  return { isError: true, content: [{ type: 'text', text: message }] }
}
