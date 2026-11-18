// Pure, DOM-free core of the Simulation Viewer (unit-tested under Node; see frontend/tests/viewerCore.test.ts).
// Nothing here simulates, interpolates or infers epidemic state: every number comes from a stored CESNAP frame.
// Only erasable TypeScript syntax is used (no enums / parameter properties) so Node can run it directly.

export const S = 0, E = 1, I = 2, R = 3
export type Counts = [number, number, number, number]
export const STATE_KEYS = ['S', 'E', 'I', 'R'] as const

export class FrameError extends Error {}

/** Count agents per state in a frame. Throws FrameError on any byte that is not a valid state (0..3). */
export function countStates(frame: Uint8Array): Counts {
  const c: Counts = [0, 0, 0, 0]
  let bad = 0
  for (let i = 0; i < frame.length; i++) { const s = frame[i]; if (s < 4) c[s]++; else bad++ }
  if (bad) throw new FrameError(`frame contains ${bad} invalid state byte(s)`)
  return c
}

/* ───────── Analytics derived from the selected frame ───────── */

export interface DayStats { counts: Counts; pct: Counts; attackRatePct: number; incidence: number; infected: number }

/** Attack rate and incidence use the same definitions as the backend (results.py): attack = 1 - S/N, incidence = max(S[t-1] - S[t], 0). */
export function deriveStats(n: number, counts: Counts, prev: Counts | null): DayStats {
  const pct = counts.map((v) => (n ? (100 * v) / n : 0)) as Counts
  return {
    counts, pct, attackRatePct: n ? 100 * (1 - counts[S] / n) : 0,
    incidence: prev ? Math.max(prev[S] - counts[S], 0) : 0, infected: n - counts[S],
  }
}

export interface SeriesLike { day: number; S: number; E: number; I: number; R: number; incidence: number }
/** Cross-check one frame against the daily CSV row for the same day. Returns human-readable mismatches (empty = identical). */
export function verifyAgainstSeries(counts: Counts, incidence: number, row: SeriesLike | undefined, day: number): string[] {
  if (!row) return [`no daily CSV row for day ${day}`]
  const out: string[] = []
  if (row.day !== day) out.push(`CSV row is for day ${row.day}, expected ${day}`)
  STATE_KEYS.forEach((k, i) => { if (row[k] !== counts[i]) out.push(`${k}: snapshot ${counts[i]} vs CSV ${row[k]}`) })
  if (row.incidence !== incidence) out.push(`incidence: snapshot ${incidence} vs CSV ${row.incidence}`)
  return out
}

/* ───────── Positions ───────── */

export class Positions {
  n: number
  lon: Float32Array
  lat: Float32Array
  mx: Float64Array // Web-Mercator world coordinates in [0,1] (precision-safe at zoom 19)
  my: Float64Array
  bounds: [number, number, number, number] // south, west, north, east
  constructor(buf: ArrayBuffer, n: number) {
    if (buf.byteLength !== 8 * n) throw new FrameError(`home positions are ${buf.byteLength} bytes; expected ${8 * n} for ${n} agents`)
    const f = new Float32Array(buf)
    this.n = n
    this.lon = new Float32Array(n); this.lat = new Float32Array(n)
    this.mx = new Float64Array(n); this.my = new Float64Array(n)
    let s = Infinity, w = Infinity, nn = -Infinity, e = -Infinity
    for (let i = 0; i < n; i++) {
      const lo = f[2 * i], la = f[2 * i + 1]
      if (!Number.isFinite(lo) || !Number.isFinite(la) || la < -85 || la > 85 || lo < -180 || lo > 180) throw new FrameError(`agent ${i} has an invalid home coordinate (${lo}, ${la})`)
      this.lon[i] = lo; this.lat[i] = la
      this.mx[i] = (lo + 180) / 360
      this.my[i] = 0.5 - Math.log(Math.tan(Math.PI / 4 + (la * Math.PI) / 360)) / (2 * Math.PI)
      if (la < s) s = la; if (la > nn) nn = la; if (lo < w) w = lo; if (lo > e) e = lo
    }
    this.bounds = [s, w, nn, e]
  }
}

/* ───────── Spatial grid aggregation ───────── */

export interface Grid { zb: number; cellPx: number; cellLon: number; cellLat: number; cx0: number; cy0: number; w: number; h: number; cell: Int32Array; ncells: number }
export const INDIVIDUAL_ZOOM = 14 // at or above this map zoom individual agents are drawn; below it, grid cells

/** Geo-anchored grid whose cells are about `cellPx` pixels wide at integer zoom bucket `zb`. Independent of the frame, so it is built once per zoom bucket. */
export function buildGrid(pos: Positions, zb: number, cellPx = 16): Grid {
  const cellLon = (360 / (256 * 2 ** zb)) * cellPx
  const lat0 = (pos.bounds[0] + pos.bounds[2]) / 2
  const cellLat = cellLon * Math.cos((lat0 * Math.PI) / 180) // square on screen under Mercator
  let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity
  const cx = new Int32Array(pos.n), cy = new Int32Array(pos.n)
  for (let i = 0; i < pos.n; i++) {
    const a = Math.floor(pos.lon[i] / cellLon), b = Math.floor(pos.lat[i] / cellLat)
    cx[i] = a; cy[i] = b
    if (a < x0) x0 = a; if (a > x1) x1 = a; if (b < y0) y0 = b; if (b > y1) y1 = b
  }
  const w = x1 - x0 + 1, h = y1 - y0 + 1
  if (!(w * h > 0) || w * h > 4_000_000) throw new FrameError(`grid at zoom ${zb} would have ${w}x${h} cells`)
  const cell = new Int32Array(pos.n)
  for (let i = 0; i < pos.n; i++) cell[i] = (cy[i] - y0) * w + (cx[i] - x0)
  return { zb, cellPx, cellLon, cellLat, cx0: x0, cy0: y0, w, h, cell, ncells: w * h }
}

/** Per-cell S/E/I/R counts (layout: cell*4 + state) for one frame. O(N). */
export function gridCounts(grid: Grid, frame: Uint8Array): Uint32Array {
  const out = new Uint32Array(grid.ncells * 4), cell = grid.cell
  for (let i = 0; i < frame.length; i++) out[cell[i] * 4 + frame[i]]++
  return out
}

/* ───────── Colours ───────── */

export const STATE_RGB: [number, number, number][] = [[91, 155, 196], [217, 152, 42], [224, 115, 94], [110, 164, 122]] // S blue, E amber, I coral, R green (= lib/theme SEIR)

/** Proportional RGB mix of the four state colours for a cell (composition view). Exact proportions; no emphasis added. */
export function mixColor(c: Uint32Array, o: number): [number, number, number] {
  const t = c[o] + c[o + 1] + c[o + 2] + c[o + 3]
  if (!t) return [0, 0, 0]
  let r = 0, g = 0, b = 0
  for (let k = 0; k < 4; k++) { const f = c[o + k] / t; r += STATE_RGB[k][0] * f; g += STATE_RGB[k][1] * f; b += STATE_RGB[k][2] * f }
  return [Math.round(r), Math.round(g), Math.round(b)]
}

/** Sequential ramp for the "active infection" view: share of agents that are E or I. 0 -> slate-blue, 1 -> deep coral. */
export function prevalenceColor(share: number): [number, number, number] {
  const t = Math.min(1, Math.max(0, share)), a = [58, 84, 110], m = [217, 152, 42], b = [224, 80, 60]
  const u = t < 0.5 ? t / 0.5 : (t - 0.5) / 0.5, f = t < 0.5 ? a : m, g = t < 0.5 ? m : b
  return [0, 1, 2].map((i) => Math.round(f[i] + (g[i] - f[i]) * u)) as [number, number, number]
}

/* ───────── Playback state machine ───────── */

export const SPEEDS = [0.5, 1, 2, 4] as const
export const BASE_DAYS_PER_SEC = 4 // 1x = four stored frames per second
export interface PlayState { day: number; last: number; playing: boolean; speed: number; acc: number; buffering: boolean }
export type PlayAction =
  | { type: 'play' } | { type: 'pause' } | { type: 'reset' } | { type: 'seek'; day: number } | { type: 'speed'; speed: number }
  | { type: 'tick'; dtMs: number; ready: (day: number) => boolean }

export const initialPlay = (last: number): PlayState => ({ day: 0, last, playing: false, speed: 1, acc: 0, buffering: false })

/** Advances only along integer stored days: never fractional, never interpolated. */
export function playReducer(s: PlayState, a: PlayAction): PlayState {
  switch (a.type) {
    case 'play': return s.playing ? s : { ...s, playing: true, day: s.day >= s.last ? 0 : s.day, acc: 0 }
    case 'pause': return { ...s, playing: false, acc: 0, buffering: false }
    case 'reset': return { ...s, day: 0, playing: false, acc: 0, buffering: false }
    case 'seek': return { ...s, day: Math.min(s.last, Math.max(0, Math.round(a.day))), acc: 0, buffering: false }
    case 'speed': return SPEEDS.includes(a.speed as typeof SPEEDS[number]) ? { ...s, speed: a.speed } : s
    case 'tick': {
      if (!s.playing) return s
      let acc = s.acc + (Math.min(a.dtMs, 250) / 1000) * s.speed * BASE_DAYS_PER_SEC // cap dt so a background tab cannot skip the run
      let day = s.day, playing = true, buffering = false
      while (acc >= 1 - 1e-9) { // epsilon: 20 x 50 ms at 0.5x must land exactly on day 2
        const next = day + 1
        if (next > s.last) { playing = false; acc = 0; break }
        if (!a.ready(next)) { buffering = true; acc = 1; break } // wait for the real frame; never skip ahead to fake it
        day = next; acc = Math.max(0, acc - 1)
      }
      return { ...s, day, acc, playing, buffering }
    }
  }
}

/* ───────── Frame store ───────── */

export class FrameStore {
  n: number
  nFrames: number
  private fetchFrame: (day: number) => Promise<Uint8Array>
  private frames = new Map<number, Uint8Array>() // insertion order doubles as LRU order
  private countsMap = new Map<number, Counts>() // tiny; kept for every day ever loaded
  private pending = new Map<number, Promise<void>>()
  errors = new Map<number, string>()
  maxFrames: number
  version = 0
  private listeners = new Set<() => void>()
  constructor(n: number, nFrames: number, fetchFrame: (day: number) => Promise<Uint8Array>, budgetBytes = 384 * 2 ** 20) {
    this.n = n; this.nFrames = nFrames; this.fetchFrame = fetchFrame
    this.maxFrames = Math.max(3, Math.floor(budgetBytes / Math.max(1, n)))
  }
  subscribe(fn: () => void) { this.listeners.add(fn); return () => { this.listeners.delete(fn) } }
  private notify() { this.version++; this.listeners.forEach((f) => f()) }
  has(d: number) { return this.frames.has(d) }
  frame(d: number): Uint8Array | undefined { const f = this.frames.get(d); if (f) { this.frames.delete(d); this.frames.set(d, f) } return f }
  counts(d: number) { return this.countsMap.get(d) }
  get loaded() { return this.countsMap.size }
  get residentBytes() { return this.frames.size * this.n }
  /** Selected frame is displayable once its pixels and the previous day's counts (for incidence) are known. */
  ready(d: number) { return this.frames.has(d) && (d === 0 || this.countsMap.has(d - 1)) }

  private load(d: number): Promise<void> {
    if (this.frames.has(d)) return Promise.resolve()
    let p = this.pending.get(d)
    if (!p) {
      p = this.fetchFrame(d).then((f) => {
        if (f.length !== this.n) throw new FrameError(`day ${d}: frame has ${f.length} bytes, expected ${this.n}`)
        this.countsMap.set(d, countStates(f))
        this.frames.set(d, f); this.errors.delete(d)
        while (this.frames.size > this.maxFrames) this.frames.delete(this.frames.keys().next().value as number)
        this.notify()
      }).catch((e: Error) => { this.errors.set(d, e.message); this.notify(); throw e }).finally(() => { this.pending.delete(d) })
      this.pending.set(d, p)
    }
    return p
  }
  /** Make day d displayable (also fetches d-1 when its counts are unknown). */
  async ensure(d: number) {
    if (d < 0 || d >= this.nFrames) throw new FrameError(`day ${d} is outside 0..${this.nFrames - 1}`)
    const need = [this.load(d)]
    if (d > 0 && !this.countsMap.has(d - 1)) need.push(this.load(d - 1))
    await Promise.all(need)
  }
  /** Background-load frames in day order with bounded concurrency until the memory budget is reached. Individual failures are recorded, not fatal. */
  async preload(concurrency = 6, shouldStop: () => boolean = () => false) {
    let next = 0
    const limit = Math.min(this.nFrames, this.maxFrames)
    const worker = async () => {
      while (!shouldStop()) {
        const d = next++
        if (d >= limit) return
        try { await this.load(d) } catch { /* recorded in errors */ }
      }
    }
    await Promise.all(Array.from({ length: concurrency }, worker))
  }
}
