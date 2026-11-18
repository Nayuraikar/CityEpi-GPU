import { C } from './theme'

export const nf = (n: number | null | undefined, d = 0) =>
  n == null || Number.isNaN(n) ? '—' : n.toLocaleString('en-US', { maximumFractionDigits: d, minimumFractionDigits: d })
export const pct = (n: number | null | undefined, d = 1) => (n == null ? '—' : `${nf(n, d)}%`)
export const secs = (s: number | null | undefined) => {
  if (s == null) return '—'
  if (s < 1e-3) return `${nf(s * 1e6, 0)} µs`
  if (s < 1) return `${nf(s * 1e3, s < 0.01 ? 2 : 1)} ms`
  return `${nf(s, 2)} s`
}
export const x = (n: number | null | undefined) => (n == null ? '—' : `${nf(n, n >= 100 ? 0 : 1)}×`)
export const compact = (n: number) => Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 }).format(n)

export const SCENARIO_COLORS: Record<string, string> = {
  legacy: C.lavender, household: C.teal, low: C.glacier, baseline: C.amber, high: C.coral,
}
export const CAT_COLORS: Record<string, string> = {
  education: C.glacier, healthcare: C.coral, industrial: C.lavender, office: C.amber,
  commercial_retail: C.terracotta, civic_public: C.teal, leisure: C.sage,
}
export const catLabel = (c: string) => c.replace('_', ' / ').replace(/\b\w/g, (m) => m.toUpperCase())
