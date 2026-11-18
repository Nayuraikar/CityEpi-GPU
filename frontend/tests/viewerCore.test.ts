// Run: cd frontend && node --experimental-strip-types --test tests/viewerCore.test.ts
// Live checks run when CITYEPI_API (default http://127.0.0.1:8000) serves a completed snapshot run given by CITYEPI_RUN.
import test from 'node:test'
import assert from 'node:assert/strict'
import {
  BASE_DAYS_PER_SEC, buildGrid, countStates, deriveStats, FrameError, FrameStore, gridCounts, initialPlay, mixColor, playReducer, Positions,
  prevalenceColor, verifyAgainstSeries,
} from '../src/lib/viewerCore.ts'
import type { Counts, PlayAction, PlayState } from '../src/lib/viewerCore.ts'

const frameOf = (states: number[]) => Uint8Array.from(states)
const allReady = () => true

/* ───────── counts / analytics ───────── */
test('countStates counts each state and rejects invalid bytes', () => {
  assert.deepEqual(countStates(frameOf([0, 0, 1, 2, 2, 2, 3])), [2, 1, 3, 1])
  assert.throws(() => countStates(frameOf([0, 4])), FrameError)
})

test('deriveStats uses the backend definitions (attack = 1-S/N, incidence = max(S[t-1]-S[t],0))', () => {
  const s = deriveStats(1000, [900, 40, 50, 10], [950, 0, 50, 0])
  assert.ok(Math.abs(s.attackRatePct - 10) < 1e-9); assert.equal(s.incidence, 50); assert.ok(s.pct.every((v, i) => Math.abs(v - [90, 4, 5, 1][i]) < 1e-9))
  assert.equal(deriveStats(1000, [950, 0, 50, 0], null).incidence, 0)
  assert.equal(deriveStats(10, [4, 0, 0, 6], [5, 0, 0, 5]).incidence, 1)
  assert.equal(deriveStats(10, [6, 0, 0, 4], [5, 0, 0, 5]).incidence, 0) // S never grows; clamp is defensive
})

test('verifyAgainstSeries reports exact mismatches', () => {
  const row = { day: 3, S: 5, E: 2, I: 2, R: 1, incidence: 1 }
  assert.deepEqual(verifyAgainstSeries([5, 2, 2, 1], 1, row, 3), [])
  assert.equal(verifyAgainstSeries([5, 2, 3, 0], 1, row, 3).length, 2)
  assert.match(verifyAgainstSeries([5, 2, 2, 1], 1, row, 4)[0], /expected 4/)
  assert.match(verifyAgainstSeries([5, 2, 2, 1], 1, undefined, 9)[0], /no daily CSV row/)
})

/* ───────── positions & grid ───────── */
function makePositions(n: number, seed = 1) {
  let x = seed
  const rnd = () => { x = (x * 1664525 + 1013904223) >>> 0; return x / 2 ** 32 }
  const f = new Float32Array(2 * n)
  for (let i = 0; i < n; i++) { f[2 * i] = 77.4 + rnd() * 0.3; f[2 * i + 1] = 12.85 + rnd() * 0.25 }
  return { f, pos: new Positions(f.buffer, n) }
}

test('Positions validates size and coordinates', () => {
  assert.throws(() => new Positions(new ArrayBuffer(15), 2), FrameError)
  assert.throws(() => new Positions(new Float32Array([NaN, 12]).buffer, 1), FrameError)
  assert.throws(() => new Positions(new Float32Array([77, 95]).buffer, 1), FrameError)
  const { pos } = makePositions(1000)
  assert.ok(pos.bounds[0] >= 12.85 && pos.bounds[2] <= 13.1 && pos.bounds[1] >= 77.4)
  assert.ok(pos.mx.every((v) => v > 0 && v < 1) && pos.my.every((v) => v > 0 && v < 1))
})

test('grid aggregation conserves agents per state at every zoom and matches brute force', () => {
  const n = 5000, { pos } = makePositions(n, 7)
  const frame = Uint8Array.from({ length: n }, (_, i) => (i * 7 + (i >> 3)) % 4)
  const want = countStates(frame)
  for (const zb of [9, 10, 11, 12, 13]) {
    const g = buildGrid(pos, zb), c = gridCounts(g, frame)
    const tot: Counts = [0, 0, 0, 0]
    for (let i = 0; i < c.length; i++) tot[i % 4] += c[i]
    assert.deepEqual(tot, want, `zoom ${zb}`)
    // brute force one cell
    const k = g.cell[123], o = k * 4, bf = [0, 0, 0, 0]
    for (let i = 0; i < n; i++) if (g.cell[i] === k) bf[frame[i]]++
    assert.deepEqual([c[o], c[o + 1], c[o + 2], c[o + 3]], bf)
  }
  assert.ok(buildGrid(pos, 9).ncells < buildGrid(pos, 13).ncells, 'finer zoom -> more cells')
})

test('colour helpers', () => {
  assert.deepEqual(mixColor(Uint32Array.from([10, 0, 0, 0]), 0), [91, 155, 196])   // pure S = blue
  assert.deepEqual(mixColor(Uint32Array.from([0, 0, 5, 0]), 0), [224, 115, 94])    // pure I = coral
  assert.deepEqual(mixColor(Uint32Array.from([0, 0, 0, 0]), 0), [0, 0, 0])
  assert.deepEqual(prevalenceColor(0), [58, 84, 110]); assert.deepEqual(prevalenceColor(1), [224, 80, 60]); assert.deepEqual(prevalenceColor(9), [224, 80, 60])
})

/* ───────── playback state machine ───────── */
const run = (s: PlayState, ...a: PlayAction[]) => a.reduce(playReducer, s)
const tick = (ms: number, ready: (d: number) => boolean = allReady): PlayAction => ({ type: 'tick', dtMs: ms, ready })

test('play / pause / reset / seek / speed', () => {
  let s = initialPlay(100)
  assert.equal(s.day, 0); assert.equal(s.playing, false)
  s = run(s, { type: 'play' }); assert.equal(s.playing, true)
  s = run(s, tick(250)); assert.equal(s.day, 1) // 1x = 4 frames/s
  s = run(s, { type: 'pause' }, tick(1000)); assert.equal(s.day, 1) // paused clock does not advance
  s = run(s, { type: 'seek', day: 50 }); assert.equal(s.day, 50); assert.equal(s.playing, false)
  s = run(s, { type: 'seek', day: 1000 }); assert.equal(s.day, 100)
  s = run(s, { type: 'seek', day: -5 }); assert.equal(s.day, 0)
  s = run(s, { type: 'seek', day: 12.7 }); assert.equal(s.day, 13) // integer days only
  s = run(s, { type: 'play' }, { type: 'reset' }); assert.deepEqual([s.day, s.playing], [0, false])
  assert.equal(run(s, { type: 'speed', speed: 3 }).speed, 1) // unsupported speed ignored
})

test('speeds 0.5x/1x/2x/4x advance 2/4/8/16 stored days per second, only whole days', () => {
  for (const [sp, want] of [[0.5, 2], [1, 4], [2, 8], [4, 16]] as const) {
    let s = run(initialPlay(100), { type: 'speed', speed: sp }, { type: 'play' })
    const seen: number[] = []
    for (let t = 0; t < 1000; t += 50) { s = run(s, tick(50)); seen.push(s.day) }
    assert.equal(s.day, want, `${sp}x`)
    assert.ok(seen.every(Number.isInteger))
    assert.ok(seen.every((d, i) => d >= (seen[i - 1] ?? 0)))
  }
  assert.equal(BASE_DAYS_PER_SEC, 4)
})

test('speed change mid-playback keeps the current day', () => {
  let s = run(initialPlay(100), { type: 'play' }, tick(250), tick(250)); assert.equal(s.day, 2)
  s = run(s, { type: 'speed', speed: 4 }); assert.equal(s.day, 2); assert.equal(s.playing, true)
  s = run(s, tick(250)); assert.equal(s.day, 6)
})

test('playback stops at the last frame; Play there restarts from day 0', () => {
  let s = run(initialPlay(5), { type: 'speed', speed: 4 }, { type: 'play' }, tick(250), tick(250), tick(250))
  assert.equal(s.day, 5); assert.equal(s.playing, false)
  s = run(s, { type: 'play' }); assert.deepEqual([s.day, s.playing], [0, true])
})

test('buffering: playback waits for a real frame and never skips or fabricates one', () => {
  const have = new Set([0, 1, 2])
  let s = run(initialPlay(100), { type: 'play' })
  for (let i = 0; i < 20; i++) s = run(s, tick(250, (d) => have.has(d)))
  assert.equal(s.day, 2); assert.equal(s.buffering, true); assert.equal(s.playing, true)
  have.add(3); s = run(s, tick(16, (d) => have.has(d)))
  assert.equal(s.day, 3); assert.equal(s.buffering, false)
})

test('a background-tab gap (huge dt) cannot jump the run forward', () => {
  const s = run(initialPlay(100), { type: 'play' }, tick(60_000))
  assert.ok(s.day <= 1)
})

/* ───────── frame store ───────── */
const mkFrames = (n: number, F: number) => Array.from({ length: F }, (_, d) => Uint8Array.from({ length: n }, (_, i) => (i < d ? 3 : 0)))

test('FrameStore loads, counts, and exposes ready() only with previous counts', async () => {
  const frames = mkFrames(20, 6), calls: number[] = []
  const st = new FrameStore(20, 6, async (d) => { calls.push(d); return frames[d] })
  assert.equal(st.ready(0), false)
  await st.ensure(3)
  assert.deepEqual([...calls].sort(), [2, 3]) // d and d-1 (for incidence)
  assert.ok(st.ready(3)); assert.deepEqual(st.counts(3), [17, 0, 0, 3])
  assert.equal(st.ready(4), false)
  await st.preload(2); assert.equal(st.loaded, 6); assert.equal(st.residentBytes, 6 * 20)
  assert.equal(calls.filter((d) => d === 3).length, 1, 'no duplicate fetches')
})

test('FrameStore rejects wrong-size frames, records errors, and recovers on retry', async () => {
  let bad = true
  const st = new FrameStore(4, 3, async (d) => (d === 1 && bad ? new Uint8Array(3) : new Uint8Array(4)))
  await assert.rejects(st.ensure(1), FrameError)
  assert.match(st.errors.get(1)!, /expected 4/); assert.equal(st.ready(1), false)
  await st.preload(3); assert.equal(st.loaded, 2) // day 1 failed but the rest loaded
  bad = false; await st.ensure(1); assert.ok(st.ready(1)); assert.equal(st.errors.size, 0)
  await assert.rejects(st.ensure(9), FrameError)
})

test('FrameStore evicts frames over its memory budget but keeps counts', async () => {
  const st = new FrameStore(10, 50, async () => new Uint8Array(10), 10 * 4) // budget = 4 frames (min 3)
  await st.preload(1)
  assert.ok(st.residentBytes <= 40); assert.equal(st.loaded, 4)
  for (const d of [10, 11, 12, 13, 14, 15]) await st.ensure(d)
  assert.ok(st.residentBytes <= 40); assert.ok(st.counts(10) !== undefined)
})

/* ───────── live API (optional) ───────── */
const API = process.env.CITYEPI_API ?? 'http://127.0.0.1:8000', RUN = process.env.CITYEPI_RUN
test('LIVE: 100k agents x 101 frames match the snapshot API and the daily CSV; days 0/1/50/100', { skip: !RUN }, async () => {
  const j = async (u: string) => (await fetch(API + u)).json()
  const meta = await j(`/api/sim/runs/${RUN}/snapshots`)
  const { n_agents: n, n_frames: F } = meta.info
  assert.equal(n, 100000); assert.equal(F, 101)
  const csv = (await (await fetch(`${API}/api/sim/runs/${RUN}/export.csv`)).text()).trim().split('\n')
  const header = csv.findIndex((l) => l.startsWith('day'))
  const rows = csv.slice(header + 1).map((l) => l.split(',').map(Number))
  assert.equal(rows.length, F)

  const pos = new Positions(await (await fetch(`${API}/api/sim/runs/${RUN}/snapshots/home-positions`)).arrayBuffer(), n)
  assert.ok(pos.bounds[0] > 12.7 && pos.bounds[2] < 13.3 && pos.bounds[1] > 77.3 && pos.bounds[3] < 77.9, `Bengaluru bounds ${pos.bounds}`)

  const mem0 = process.memoryUsage().heapUsed + process.memoryUsage().arrayBuffers
  const store = new FrameStore(n, F, async (d) => {
    const r = await fetch(`${API}/api/sim/runs/${RUN}/snapshots/frames/${d}`)
    assert.equal(Number(r.headers.get('x-day')), d)
    return new Uint8Array(await r.arrayBuffer())
  })
  const t0 = performance.now(); await store.preload(6); const loadMs = performance.now() - t0
  assert.equal(store.loaded, F); assert.equal(store.errors.size, 0)
  let prev: Counts | null = null
  const report: string[] = []
  for (let d = 0; d < F; d++) {
    const c = store.counts(d)!, [dd, S, E, I, R] = rows[d]
    assert.equal(dd, d)
    assert.deepEqual(c, [S, E, I, R], `day ${d} counts vs CSV`)
    assert.equal(c[0] + c[1] + c[2] + c[3], n)
    const st = deriveStats(n, c, prev)
    assert.deepEqual(verifyAgainstSeries(c, st.incidence, { day: dd, S, E, I, R, incidence: prev ? Math.max(prev[0] - S, 0) : 0 }, d), [])
    if ([0, 1, 50, 100].includes(d)) report.push(`day ${d}: S=${S} E=${E} I=${I} R=${R} attack=${st.attackRatePct.toFixed(3)}% incidence=${st.incidence}`)
    prev = c
  }
  assert.deepEqual(store.counts(0), [99900, 0, 100, 0].map((v, i) => v) as Counts) // seeded state
  // frame 0 should have exactly the seeded infectious agents; day 100 matches the run result
  const res = (await j(`/api/sim/runs/${RUN}`)).result
  const f100 = store.counts(100)!
  assert.equal(+(100 * (1 - f100[0] / n)).toFixed(3), res.attack_rate_pct)

  // aggregation at every grid zoom on real data: conservation + timing
  const t: string[] = []
  for (const zb of [9, 10, 11, 12, 13]) {
    const a = performance.now(), g = buildGrid(pos, zb), b = performance.now(), c = gridCounts(g, store.frame(50)!), e = performance.now()
    const tot = [0, 0, 0, 0]; for (let i = 0; i < c.length; i++) tot[i % 4] += c[i]
    assert.deepEqual(tot, store.counts(50)); t.push(`z${zb}: ${g.ncells} cells, build ${(b - a).toFixed(1)} ms, per-frame aggregate ${(e - b).toFixed(1)} ms`)
  }
  const mem1 = process.memoryUsage().heapUsed + process.memoryUsage().arrayBuffers
  console.log(`\n  LIVE ${RUN}\n  ${report.join('\n  ')}\n  all 101 frames == daily CSV (S,E,I,R, conservation, incidence)\n  load 101 frames in ${loadMs.toFixed(0)} ms (6 parallel)\n  ${t.join('\n  ')}\n  JS memory delta ${((mem1 - mem0) / 2 ** 20).toFixed(1)} MiB (frames resident: ${(store.residentBytes / 2 ** 20).toFixed(1)} MiB)`)
})
