// Client for the validated per-agent snapshot endpoints (/api/sim/runs/{id}/snapshots/*). Uncached by design.
// Frames are raw bytes (one state per agent); positions are raw float32 [lon,lat] pairs of each agent's real home_loc.

export type SnapshotFailure = 'unreachable' | 'not_requested' | 'not_ready' | 'unavailable' | 'invalid' | 'http'

export class SnapshotError extends Error {
  constructor(public kind: SnapshotFailure, message: string, public status = 0) { super(message) }
}

export interface SnapshotInfo {
  format: string; version: number; backend: string; n_agents: number; n_frames: number; n_days: number; bits_per_agent: number
  state_encoding: string; frame_semantics: string; file_bytes: number; seed: number; dataset_payload_crc32: string
}
export interface SnapshotMeta { available: boolean; validated: boolean; supported_backends: string[]; info: SnapshotInfo; notes: string[] }

async function get(url: string): Promise<Response> {
  let r: Response
  try { r = await fetch(url, { cache: 'no-store' }) } catch { throw new SnapshotError('unreachable', 'Cannot reach the API server. Is the FastAPI backend running?') }
  if (r.ok) return r
  let detail = `${r.status} ${r.statusText}`
  try { const j = await r.json(); if (typeof j.detail === 'string') detail = j.detail } catch { /* non-JSON body */ }
  const kind: SnapshotFailure = r.status === 409 ? 'not_ready' : r.status === 404 ? (/did not request/.test(detail) ? 'not_requested' : 'unavailable') : 'http'
  throw new SnapshotError(kind, detail, r.status)
}

const base = (id: string) => `/api/sim/runs/${encodeURIComponent(id)}/snapshots`

export async function fetchSnapshotMeta(runId: string): Promise<SnapshotMeta> {
  const m = (await (await get(base(runId))).json()) as SnapshotMeta
  const i = m?.info
  if (!i || !Number.isInteger(i.n_agents) || !Number.isInteger(i.n_frames) || i.n_agents <= 0 || i.n_frames <= 0) throw new SnapshotError('invalid', 'The snapshot metadata is malformed.')
  return m
}

export async function fetchHomePositions(runId: string, n: number): Promise<ArrayBuffer> {
  const r = await get(`${base(runId)}/home-positions`)
  const buf = await r.arrayBuffer()
  if (buf.byteLength !== 8 * n) throw new SnapshotError('invalid', `Home positions are ${buf.byteLength} bytes; expected ${8 * n} for ${n} agents.`)
  return buf
}

export async function fetchFrame(runId: string, day: number, n: number): Promise<Uint8Array> {
  const r = await get(`${base(runId)}/frames/${day}`)
  const day2 = r.headers.get('X-Day')
  if (day2 != null && Number(day2) !== day) throw new SnapshotError('invalid', `Asked for day ${day} but the server returned day ${day2}.`)
  const buf = new Uint8Array(await r.arrayBuffer())
  if (buf.length !== n) throw new SnapshotError('invalid', `Day ${day}: frame has ${buf.length} bytes; expected ${n}.`)
  return buf
}
