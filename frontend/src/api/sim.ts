// Typed client for the simulation execution API (/api/sim/*). Mirrors backend/app/sim/{api,models,runs}.py.
// Deliberately uncached: every call hits the live API.

export interface SimDataset { id: string; label: string; agents: number; locations: number; households: boolean; file_bytes: number }
export interface SimBackend { id: string; label: string; description: string; hardware: 'cpu' | 'gpu'; progress_per_day: boolean; supports_snapshots?: boolean; available: boolean; reason: string | null; executable: string | null; device?: string | null }
export interface SimDefaults { days: number; seed: number; initial_infected: number; beta_home: number; beta_work: number; incubation_days: number; infectious_days: number; timeout_seconds: number }
export interface SimCapabilities {
  datasets: SimDataset[]; backends: SimBackend[]; limits: Record<string, [number, number]>; defaults: SimDefaults
  max_concurrent_runs: number; snapshot_max_days?: number; host: { platform: string; machine: string; cpu: string; cpu_count: number }; model_notes: string[]
}
export interface SimRequest { dataset: string; backend: string; days: number; seed: number; initial_infected: number; beta_home: number; beta_work: number; incubation_days: number; infectious_days: number; snapshots?: boolean }
export interface FieldIssue { field: string; message: string }
export interface SimValidation { valid: boolean; errors: FieldIssue[]; warnings: FieldIssue[] }

export type RunState = 'queued' | 'running' | 'completed' | 'failed' | 'cancelled'
export const TERMINAL: RunState[] = ['completed', 'failed', 'cancelled']
export const isTerminal = (s: RunState) => TERMINAL.includes(s)

export interface RunProgress { supported: boolean; day: number | null; total_days: number; fraction: number | null; S: number | null; E: number | null; I: number | null; R: number | null; sim_elapsed_seconds: number | null }
export interface RunResult {
  agents: number; days: number; final: { S: number; E: number; I: number; R: number }
  attack_rate_pct: number; recovered_pct: number; peak_infectious: number; peak_day: number
  peak_daily_incidence: number; peak_incidence_day: number; runtime_seconds: number | null; daily_checksum: string | null
}
export interface RunSnapshots { requested: boolean; available: boolean; backend_support?: string }
export interface Run {
  id: string; state: RunState; label: string | null; created_at: string; started_at: string | null; finished_at: string | null
  request: Omit<SimRequest, 'dataset' | 'backend'>
  dataset: { id: string; label: string; agents: number; locations: number; households: boolean }
  backend: { id: string; label: string; hardware: string; device: string | null }
  snapshots?: RunSnapshots
  progress: RunProgress; exit_code: number | null; error: { code: string; message: string } | null; result: RunResult | null
}
export interface SeriesRow { day: number; S: number; E: number; I: number; R: number; incidence: number }

export class ApiError extends Error {
  constructor(public status: number, message: string, public errors: FieldIssue[] = []) { super(message) }
}

async function call<T>(url: string, init?: RequestInit): Promise<T> {
  let r: Response
  try { r = await fetch(url, init) } catch { throw new ApiError(0, 'Cannot reach the API server. Is the FastAPI backend running?') }
  if (!r.ok) {
    let msg = `${r.status} ${r.statusText}`, errors: FieldIssue[] = []
    try { const j = await r.json(); msg = typeof j.detail === 'string' ? j.detail : msg; errors = j.errors ?? [] } catch { /* non-JSON body */ }
    throw new ApiError(r.status, msg, errors)
  }
  return r.status === 204 ? (undefined as T) : r.json()
}
const post = (body: unknown): RequestInit => ({ method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) })

export const sim = {
  capabilities: (refresh = false) => call<SimCapabilities>(`/api/sim/capabilities${refresh ? '?refresh=true' : ''}`),
  validate: (req: unknown) => call<SimValidation>('/api/sim/validate', post(req)),
  start: (req: SimRequest) => call<Run>('/api/sim/runs', post(req)),
  list: () => call<{ runs: Run[] }>('/api/sim/runs'),
  get: (id: string) => call<Run>(`/api/sim/runs/${id}`),
  series: (id: string, since = -1) => call<{ state: RunState; rows: SeriesRow[]; n_days_available: number }>(`/api/sim/runs/${id}/series?since=${since}`),
  cancel: (id: string) => call<Run>(`/api/sim/runs/${id}/cancel`, { method: 'POST' }),
  remove: (id: string) => call<void>(`/api/sim/runs/${id}`, { method: 'DELETE' }),
  log: (id: string, stream: 'stderr' | 'stdout', tail = 200) => call<{ stream: string; lines: string[] }>(`/api/sim/runs/${id}/log?stream=${stream}&tail=${tail}`),
  exportUrl: (id: string, fmt: 'csv' | 'json') => `/api/sim/runs/${id}/export.${fmt}`,
}

/** Wall-clock seconds between two ISO timestamps (end defaults to now). Null if not started. */
export function wallSeconds(startedAt: string | null, finishedAt: string | null, now = Date.now()): number | null {
  if (!startedAt) return null
  const s = Date.parse(startedAt), e = finishedAt ? Date.parse(finishedAt) : now
  return Number.isFinite(s) && Number.isFinite(e) ? Math.max(0, (e - s) / 1000) : null
}

export type FormValues = Record<'days' | 'seed' | 'initial_infected' | 'beta_home' | 'beta_work' | 'incubation_days' | 'infectious_days', string>
const INT_FIELDS = ['days', 'seed', 'initial_infected', 'incubation_days', 'infectious_days'] as const
const LIMIT_KEY: Record<string, string> = { beta_home: 'beta', beta_work: 'beta' }

/** Client-side range/format check using the limits the server published. Server validation remains authoritative. */
export function checkForm(v: FormValues, limits: Record<string, [number, number]>, agents?: number, snapshotMaxDays?: number): Record<string, string> {
  const out: Record<string, string> = {}
  for (const k of Object.keys(v) as (keyof FormValues)[]) {
    const raw = v[k].trim()
    if (raw === '' || !Number.isFinite(Number(raw))) { out[k] = 'Enter a number'; continue }
    const n = Number(raw)
    if ((INT_FIELDS as readonly string[]).includes(k) && !Number.isInteger(n)) { out[k] = 'Must be a whole number'; continue }
    const lim = limits[LIMIT_KEY[k] ?? k]
    if (lim && (n < lim[0] || n > lim[1])) out[k] = `Must be between ${lim[0]} and ${lim[1]}`
  }
  if (!out.initial_infected && agents != null && Number(v.initial_infected) > agents) out.initial_infected = `Initial infected (${Number(v.initial_infected).toLocaleString('en-US')}) cannot exceed the selected population size (${agents.toLocaleString('en-US')} agents)`
  if (snapshotMaxDays != null && !out.days && Number(v.days) > snapshotMaxDays) out.days = `Snapshot runs are limited to ${snapshotMaxDays} days (clear “Record per-agent snapshots” for longer runs)`
  return out
}

export function toRequest(dataset: string, backend: string, v: FormValues, snapshots = false): SimRequest {
  return { ...(snapshots ? { snapshots: true } : {}), dataset, backend, days: +v.days, seed: +v.seed, initial_infected: +v.initial_infected, beta_home: +v.beta_home, beta_work: +v.beta_work, incubation_days: +v.incubation_days, infectious_days: +v.infectious_days }
}
