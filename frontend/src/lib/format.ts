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
  legacy: '#a78bfa', household: '#5eead4', low: '#4da3ff', baseline: '#f5b83d', high: '#ff5d6c',
}
export const CAT_COLORS: Record<string, string> = {
  education: '#4da3ff', healthcare: '#ff5d6c', industrial: '#a78bfa', office: '#f5b83d',
  commercial_retail: '#fb923c', civic_public: '#5eead4', leisure: '#4ad6a0',
}
export const catLabel = (c: string) => c.replace('_', ' / ').replace(/\b\w/g, (m) => m.toUpperCase())
