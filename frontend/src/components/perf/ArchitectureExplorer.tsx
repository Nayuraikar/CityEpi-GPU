import { ReactNode, useEffect, useMemo, useState } from 'react'
import { Pause, Play, RotateCcw } from 'lucide-react'
import { Card, Notice, Segmented } from '../ui'
import { C, SEIR } from '../../lib/theme'

/* ───────── shared bits ───────── */

function useTicker(on: boolean, ms: number, max: number) {
  const [i, setI] = useState(0)
  useEffect(() => {
    if (!on) return
    const t = setInterval(() => setI((v) => (v + 1) % max), ms)
    return () => clearInterval(t)
  }, [on, ms, max])
  return [i, setI] as const
}

function PlayBtn({ on, toggle, reset }: { on: boolean; toggle: () => void; reset?: () => void }) {
  return (
    <span className="inline-flex gap-1.5">
      <button className="btn" onClick={toggle} aria-label={on ? 'Pause animation' : 'Play animation'}>{on ? <Pause size={12} /> : <Play size={12} />}{on ? 'Pause' : 'Play'}</button>
      {reset && <button className="btn" onClick={reset} aria-label="Reset animation"><RotateCcw size={12} /></button>}
    </span>
  )
}

const THREAD_COLORS = [C.teal, C.glacier, C.lavender, C.amber, C.coral, C.sage, C.terracotta, C.slate]

function Code({ children }: { children: ReactNode }) { return <code className="rounded bg-surface-3 px-1 py-0.5 font-mono text-[11px] text-ink">{children}</code> }

/* ───────── 1. Sequential ───────── */

function SequentialViz() {
  const N = 32
  const [play, setPlay] = useState(true)
  const [i, setI] = useTicker(play, 220, N)
  return (
    <div>
      <div className="mb-3 flex items-center justify-between"><span className="text-xs text-mute">One core visits agents 0 → N−1 in order. Illustration with {N} agents.</span><PlayBtn on={play} toggle={() => setPlay(!play)} reset={() => setI(0)} /></div>
      <div className="grid grid-cols-16 gap-1" style={{ gridTemplateColumns: 'repeat(16, minmax(0,1fr))' }}>
        {Array.from({ length: N }, (_, a) => (
          <div key={a} className="num grid aspect-square place-items-center rounded text-[10px] transition-colors duration-150"
            style={{ background: a === i ? C.teal : a < i ? C.teal + '33' : C.grid, color: a === i ? '#fff' : C.axis }}>{a}</div>
        ))}
      </div>
      <p className="mt-3 text-xs text-mute">Time ∝ N: processing {N} agents takes {N} sequential steps (agent <b className="text-ink">{i}</b> now). Nothing here can overlap, so the only ways to go faster are doing less work per agent (V1) or doing agents at the same time (V2–V6).</p>
    </div>
  )
}

/* ───────── 2. ILP ───────── */

function IlpViz() {
  const [v, setV] = useState<'V0' | 'V1'>('V0')
  const box = (x: number, y: number, w: number, label: string, fill: string, dim = false) => (
    <g key={`${x}-${y}`} opacity={dim ? 0.35 : 1}><rect x={x} y={y} width={w} height={26} rx={5} fill={fill} /><text x={x + w / 2} y={y + 17} textAnchor="middle" fontSize={10} fill="#fff" fontWeight={600}>{label}</text></g>
  )
  return (
    <div>
      <div className="mb-3"><Segmented value={v} onChange={setV} options={[{ id: 'V0', label: 'V0 · rand01 twice' }, { id: 'V1', label: 'V1 · staged, hoisted RNG' }]} /></div>
      <svg viewBox="0 0 560 150" className="w-full" role="img" aria-label={`Dependency chains for the exposure random draws in ${v}`}>
        <text x={4} y={14} fontSize={10} fill={C.axis}>dependent steps →</text>
        {v === 'V0' ? (<>
          <text x={4} y={44} fontSize={10} fill={C.ink}>u1 (home)</text>
          {['mix(seed)', 'mix(⊕agent)', 'mix(⊕day,slot)'].map((l, k) => box(70 + k * 82, 28, 76, l, C.slate))}
          <text x={4} y={96} fontSize={10} fill={C.ink}>u2 (work)</text>
          {['mix(seed)', 'mix(⊕agent)', 'mix(⊕day,slot)'].map((l, k) => box(70 + (k + 3) * 82, 80, 76, l, C.slate))}
          <text x={70} y={136} fontSize={11} fill={C.coral}>6 mixes per susceptible agent; the compiler cannot overlap the two out-of-line calls.</text>
        </>) : (<>
          <text x={4} y={44} fontSize={10} fill={C.ink}>shared</text>
          {box(70, 28, 100, 'mix(h_seed⊕agent)', C.lavender)}
          <text x={4} y={80} fontSize={10} fill={C.ink}>u1 (home)</text>{box(188, 64, 110, 'mix(⊕day,slot 0)', C.teal)}
          <text x={4} y={112} fontSize={10} fill={C.ink}>u2 (work)</text>{box(188, 96, 110, 'mix(⊕day,slot 1)', C.teal)}
          <text x={320} y={86} fontSize={11} fill={C.tealDeep}>← independent: can issue in the same cycles (ILP)</text>
          <text x={70} y={142} fontSize={11} fill={C.tealDeep}>3 mixes per agent; seed stage hoisted out of the loop; critical path of 2 dependent mixes.</text>
        </>)}
      </svg>
    </div>
  )
}

/* ───────── 3. OpenMP ───────── */

function OpenMpViz() {
  const N = 64
  const [T, setT] = useState(4)
  const [sched, setSched] = useState<'static' | 'dynamic' | 'guided'>('static')
  const [red, setRed] = useState<'local' | 'atomic'>('local')
  const owner = useMemo(() => {
    const o = new Array<number>(N).fill(0)
    if (sched === 'static') { const per = Math.ceil(N / T); for (let a = 0; a < N; a++) o[a] = Math.min(T - 1, Math.floor(a / per)) }
    else if (sched === 'dynamic') { const ch = 4; for (let a = 0; a < N; a++) o[a] = Math.floor(a / ch) % T }          // chunks handed out round-robin (idealised)
    else { let a = 0, k = 0, rem = N; while (a < N) { const ch = Math.max(2, Math.ceil(rem / (2 * T))); for (let j = 0; j < ch && a < N; j++, a++) o[a] = k % T; rem -= ch; k++ } }
    return o
  }, [T, sched])
  return (
    <div>
      <div className="mb-3 flex flex-wrap gap-x-6 gap-y-2">
        <Segmented mono label="Threads" value={T} onChange={setT} options={[1, 2, 4, 8].map((t) => ({ id: t, label: t }))} />
        <Segmented label="Schedule" value={sched} onChange={setSched} options={(['static', 'dynamic', 'guided'] as const).map((s) => ({ id: s, label: s }))} />
        <Segmented label="Scatter" value={red} onChange={setRed} options={[{ id: 'local' as const, label: 'private histograms' }, { id: 'atomic' as const, label: 'shared + atomic' }]} />
      </div>
      <div className="grid gap-1" style={{ gridTemplateColumns: 'repeat(32, minmax(0,1fr))' }}>
        {owner.map((t, a) => <div key={a} title={`agent ${a} → thread ${t}`} className="aspect-square rounded-sm transition-colors duration-300" style={{ background: THREAD_COLORS[t] }} />)}
      </div>
      <div className="mt-3 flex flex-wrap gap-2 text-[11px]">{Array.from({ length: T }, (_, t) => <span key={t} className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm" style={{ background: THREAD_COLORS[t] }} />thread {t} · {owner.filter((x) => x === t).length} agents</span>)}</div>
      <div className="mt-3 rounded-lg bg-surface-2 p-3 text-xs leading-relaxed text-ink-2">
        {red === 'local'
          ? <>Each thread scatters infectious tallies into its <b>own</b> histogram (memory = T × locations × 4 B; at 1M agents and 8 threads the recorded run reports 6.71 MB vs 0.84 MB shared). A second parallel loop merges them with one owner per location — no contention.</>
          : <>All threads <Code>omp atomic</Code> into <b>one</b> shared tally. Smaller memory, but concurrent updates to the same cache lines serialise: the recorded runs show this variant getting slower as threads are added.</>}
        {' '}Counts use <Code>reduction(+)</Code>: integer sums are order-independent, so results do not depend on thread count or schedule.
      </div>
      <p className="mt-2 text-[11px] text-mute">Illustration only (64 agents; dynamic uses chunk 4 handed out round-robin and guided shrinks chunks — real assignment depends on run-time timing). The measured scheduling comparison is in the Benchmarks tab.</p>
    </div>
  )
}

/* ───────── 4. SIMD ───────── */

const SNAME = ['S', 'E', 'I', 'R'] as const
function SimdViz() {
  const INC = 3, IDUR = 5
  const [st, setSt] = useState<number[]>([0, 0, 1, 2, 0, 0, 2, 3, 0, 1, 0, 0, 2, 0, 0, 0])
  const [tm, setTm] = useState<number[]>([0, 0, 1, 1, 0, 0, 3, 0, 0, 2, 0, 0, 1, 0, 0, 0])
  const [hit, setHit] = useState<boolean[]>(Array(16).fill(false).map((_, i) => i === 0 || i === 5))
  const out = st.map((s, i) => {
    const t1 = (tm[i] - (s === 1 || s === 2 ? 1 : 0) + 65536) % 65536                         // uint16 wrap, as in the code
    const z = t1 === 0
    const toI = s === 1 && z, toR = s === 2 && z, toE = s === 0 && hit[i]
    return { ns: s + (toE || toI || toR ? 1 : 0), nt: toE ? INC : toI ? IDUR : s === 1 || s === 2 ? t1 : tm[i], hit: hit[i] && s === 0 }
  })
  const cycle = (i: number) => { setSt(st.map((s, k) => (k === i ? (s + 1) % 4 : s))); setTm(tm.map((t, k) => (k === i ? ((st[i] + 1) % 4 === 1 || (st[i] + 1) % 4 === 2 ? 2 : 0) : t))) }
  const counts = SNAME.map((_, k) => out.filter((o) => o.ns === k).length)
  return (
    <div>
      <p className="mb-2 text-xs text-mute">One <Code>block16</Code> iteration of the V3 hybrid: 16 agents in a 128-bit <Code>uint8x16_t</Code> register (state) and two <Code>uint16x8_t</Code> registers (timers). Click an agent to cycle S→E→I→R; toggle “hit” on susceptible agents to emulate a successful exposure draw (that draw is scalar — NEON has no 64-bit lane multiply).</p>
      <div className="overflow-x-auto"><div className="min-w-[560px]">
        <div className="grid gap-1" style={{ gridTemplateColumns: 'auto repeat(16, minmax(0,1fr))' }}>
          <span className="label self-center pr-2">lane</span>{st.map((_, i) => <span key={i} className="num text-center text-[10px] text-mute">{i}</span>)}
          <span className="label self-center pr-2">state</span>{st.map((s, i) => <button key={i} onClick={() => cycle(i)} aria-label={`Agent ${i} state ${SNAME[s]}; click to change`} className="num rounded py-1.5 text-xs font-semibold text-white transition" style={{ background: SEIR[SNAME[s]] }}>{SNAME[s]}</button>)}
          <span className="label self-center pr-2">timer</span>{tm.map((t, i) => <span key={i} className="num rounded bg-surface-3 py-1 text-center text-xs">{t}</span>)}
          <span className="label self-center pr-2">hit</span>{hit.map((h, i) => <button key={i} disabled={st[i] !== 0} onClick={() => setHit(hit.map((v, k) => (k === i ? !v : v)))} aria-pressed={h} className={`rounded py-1 text-xs transition disabled:opacity-25 ${h ? 'bg-coral text-white' : 'bg-surface-3 text-mute'}`}>{h ? '1' : '0'}</button>)}
          <span className="label self-center pr-2">next</span>{out.map((o, i) => <span key={i} className="num rounded py-1.5 text-center text-xs font-semibold text-white transition-all duration-300" style={{ background: SEIR[SNAME[o.ns]] }}>{SNAME[o.ns]}</span>)}
          <span className="label self-center pr-2">timer′</span>{out.map((o, i) => <span key={i} className="num rounded bg-surface-3 py-1 text-center text-xs">{o.nt}</span>)}
        </div>
      </div></div>
      <div className="mt-3 flex flex-wrap items-center gap-x-5 gap-y-1 text-xs"><span className="label">next-day counts</span>{SNAME.map((n, k) => <span key={n} className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm" style={{ background: SEIR[n] }} /><b className="num">{counts[k]}</b> {n}</span>)}</div>
      <div className="mt-3 rounded-lg bg-surface-2 p-3 text-xs leading-relaxed text-ink-2">
        The transition is branch-free: <Code>t1 = t − (s∈{'{E,I}'})</Code>, <Code>z = (t1==0)</Code>, <Code>ns = s + (toE | toI | toR)</Code>, using lane-wise compare masks (<Code>vceqq_u8</Code>) and blends. Every lane executes the same instructions regardless of its state. <b>Recorded outcome:</b> the complete NEON version (<code>V3_neon</code>) was <i>slower than V1</i> on this workload (0.55–0.59× of V1 at 100k–1M agents in <code>v3_results.csv</code>, 0.59–0.68× in <code>v3_hybrid_results.csv</code>; Apple M1): the exposure draws and the scatter into <Code>nin[]</Code> stay scalar, and the lane widening/packing overhead outweighs the saved ALU work. The hybrid (scalar exposure + NEON transition) recovered to ≈1.10–1.17× V1.
      </div>
    </div>
  )
}

/* ───────── 5. OpenACC ───────── */

function OpenAccViz() {
  const steps = [
    { id: 'in', t: 'enter data copyin(st, tm, hl, wl, lt, occ, nin) create(pr)', a: 'host→device once', from: 0, active: 'copy' },
    { id: 'k1', t: 'acc parallel loop (locations): pr[l] = 1 − exp(−β·nin/occ); nin[l] = 0', a: 'kernel 1 · data stays on device', from: 1, active: 'k1' },
    { id: 'k2', t: 'acc parallel loop (agents) reduction(+: cs,ce,ci,cr) + acc atomic update nin[h|w]', a: 'kernel 2 · only 4 integers return per day', from: 1, active: 'k2' },
    { id: 'out', t: 'exit data copyout(st, tm) delete(…)', a: 'device→host once', from: 2, active: 'copy' },
  ]
  const [play, setPlay] = useState(true)
  const [i, setI] = useTicker(play, 1500, steps.length)
  const s = steps[i]
  return (
    <div>
      <div className="mb-3 flex items-center justify-between"><span className="text-xs text-mute">Steps repeat daily between “enter data” and “exit data”.</span><PlayBtn on={play} toggle={() => setPlay(!play)} reset={() => setI(0)} /></div>
      <svg viewBox="0 0 560 150" className="w-full" role="img" aria-label="OpenACC host and device data movement">
        <rect x={10} y={20} width={170} height={100} rx={10} fill={C.grid} stroke={C.line} /><text x={95} y={42} textAnchor="middle" fontSize={11} fontWeight={600} fill={C.ink}>Host (CPU) memory</text>
        <rect x={380} y={20} width={170} height={100} rx={10} fill={C.teal + '14'} stroke={C.teal} /><text x={465} y={42} textAnchor="middle" fontSize={11} fontWeight={600} fill={C.tealDeep}>Device (GPU) memory</text>
        {['st', 'tm', 'hl', 'wl'].map((a, k) => <g key={a}><rect x={405 + k * 34} y={60} width={28} height={22} rx={4} fill={s.active === 'k2' ? C.coral : C.teal} opacity={i === 0 ? 0.4 : 1} /><text x={419 + k * 34} y={75} textAnchor="middle" fontSize={10} fill="#fff">{a}</text></g>)}
        <rect x={405} y={90} width={64} height={22} rx={4} fill={s.active === 'k1' ? C.coral : C.teal} opacity={i === 0 ? 0.4 : 1} /><text x={437} y={105} textAnchor="middle" fontSize={10} fill="#fff">pr / nin</text>
        {['st', 'tm', 'hl', 'wl'].map((a, k) => <g key={a}><rect x={35 + k * 34} y={60} width={28} height={22} rx={4} fill={C.slate} /><text x={49 + k * 34} y={75} textAnchor="middle" fontSize={10} fill="#fff">{a}</text></g>)}
        <g style={{ transition: 'opacity .3s' }} opacity={s.active === 'copy' ? 1 : 0.12}>
          <path d={s.from === 0 ? 'M190 70 H370' : 'M370 90 H190'} stroke={C.amber} strokeWidth={3} markerEnd="url(#ah)" fill="none" />
          <text x={280} y={62} textAnchor="middle" fontSize={10} fill={C.amber}>{s.from === 0 ? 'PCIe copy' : 'PCIe copy'}</text>
        </g>
        <defs><marker id="ah" viewBox="0 0 8 8" refX={7} refY={4} markerWidth={7} markerHeight={7} orient="auto-start-reverse"><path d="M0 0L8 4L0 8z" fill={C.amber} /></marker></defs>
        <text x={280} y={140} textAnchor="middle" fontSize={11} fill={C.axis}>{s.a}</text>
      </svg>
      <div className="mt-1 rounded-lg bg-surface-2 p-2.5 font-mono text-[11px] text-ink-2">#pragma {s.t}</div>
      <p className="mt-3 text-xs leading-relaxed text-mute">OpenACC leaves thread mapping to the compiler (NVHPC <Code>-acc=gpu -gpu=cc75</Code>): there are no explicit blocks, warps or shared-memory tiles in the source. The data region keeps arrays resident, so the daily loop only moves counters. The compiler chooses the gang/vector shape, and the count reduction is expressed with a <Code>reduction</Code> clause rather than hand-written atomics.</p>
    </div>
  )
}

/* ───────── 6. CUDA hierarchy ───────── */

function CudaGridViz() {
  const [n, setN] = useState(1000)
  const [B, setB] = useState(256)
  const blocks = Math.ceil(n / B), wpb = B / 32, tail = blocks * B - n
  const [pick, setPick] = useState(Math.min(2, blocks - 1))
  useEffect(() => { setPick((p) => Math.min(p, blocks - 1)) }, [blocks])
  const shown = Math.min(blocks, 12)
  return (
    <div>
      <div className="mb-3 flex flex-wrap gap-x-6 gap-y-2">
        <Segmented mono label="Agents N" value={n} onChange={setN} options={[100, 1000, 10000, 100000].map((v) => ({ id: v, label: v.toLocaleString() }))} />
        <Segmented mono label="Threads/block" value={B} onChange={setB} options={[64, 128, 256, 512, 1024].map((v) => ({ id: v, label: v }))} />
      </div>
      <div className="mb-3 grid grid-cols-2 gap-2 sm:grid-cols-4 text-xs">
        {[['Grid', `${blocks.toLocaleString()} blocks`], ['Block', `${B} threads = ${wpb} warps`], ['Total threads', (blocks * B).toLocaleString()], ['Idle tail threads', `${tail} (a < n guard)`]].map(([k, v]) => <div key={k} className="rounded-lg bg-surface-2 p-2.5"><div className="label">{k}</div><div className="num mt-1 font-semibold">{v}</div></div>)}
      </div>
      <div className="flex flex-wrap gap-1.5" aria-label="Thread blocks of the grid">
        {Array.from({ length: shown }, (_, b) => <button key={b} onClick={() => setPick(b)} className={`num rounded-md border px-2 py-1.5 text-[11px] transition ${b === pick ? 'border-teal-500 bg-teal-50 text-teal-700' : 'border-line text-mute hover:border-line-2'}`}>block {b}</button>)}
        {blocks > shown && <span className="self-center text-[11px] text-mute">… {blocks - shown} more</span>}
      </div>
      <div className="mt-3 rounded-lg border border-line p-3">
        <div className="mb-2 text-xs text-ink-2">Block <b>{pick}</b>: agent ids <b className="num">{(pick * B).toLocaleString()} … {Math.min(n, (pick + 1) * B) - 1 >= pick * B ? (Math.min(n, (pick + 1) * B) - 1).toLocaleString() : '—'}</b> <span className="text-mute">(a = blockIdx.x · B + threadIdx.x)</span></div>
        <div className="grid gap-1" style={{ gridTemplateColumns: `repeat(${Math.min(wpb, 8)}, minmax(0,1fr))` }}>
          {Array.from({ length: wpb }, (_, w) => {
            const live = Math.max(0, Math.min(32, n - (pick * B + w * 32)))
            return <div key={w} title={`warp ${w}: ${live}/32 threads active`} className="rounded-md p-1.5" style={{ background: live === 32 ? C.teal + '22' : live ? C.amber + '33' : C.grid }}>
              <div className="num text-[10px] text-mute">warp {w}</div>
              <div className="mt-1 grid gap-px" style={{ gridTemplateColumns: 'repeat(8, 1fr)' }}>{Array.from({ length: 32 }, (_, l) => <span key={l} className="aspect-square rounded-[2px]" style={{ background: l < live ? C.teal : C.line }} />)}</div>
            </div>
          })}
        </div>
      </div>
      <p className="mt-3 text-xs text-mute">V5 launches <Code>kBlock</Code> threads per block (one thread per agent, one per location for the first kernel). V6 makes the block size a compile-time template parameter (64–1024, <Code>__launch_bounds__(B)</Code>) so it can be benchmarked; the recorded block-size experiment is in the CUDA deep-dive tab.</p>
    </div>
  )
}

/* ───────── 7. SIMT / warp ───────── */

function SimtViz() {
  const [pS, setPS] = useState(50)
  const lanes = useMemo(() => Array.from({ length: 32 }, (_, l) => ((l * 37 + 11) % 100) < pS), [pS])
  const nS = lanes.filter(Boolean).length
  const div = nS > 0 && nS < 32
  return (
    <div>
      <div className="mb-3 flex flex-wrap items-center gap-3 text-xs"><label htmlFor="ps" className="label">Susceptible agents in warp</label><input id="ps" type="range" min={0} max={100} step={5} value={pS} onChange={(e) => setPS(+e.target.value)} className="w-48 accent-teal-600" /><span className="num font-semibold">{nS}/32 lanes</span></div>
      <div className="grid gap-1" style={{ gridTemplateColumns: 'repeat(16, minmax(0,1fr))' }}>
        {lanes.map((on, l) => <div key={l} className="num grid aspect-square place-items-center rounded text-[10px] text-white transition-colors" style={{ background: on ? SEIR.S : SEIR.R }}>{l}</div>)}
      </div>
      <div className="mt-3 grid gap-2 sm:grid-cols-2 text-xs">
        <div className="rounded-lg bg-surface-2 p-3"><div className="label">if (s == S) {'{ RNG draws }'}</div><p className="mt-1 text-ink-2">{div ? <>Warp <b>diverges</b>: the {nS} susceptible lanes execute the draw while the other {32 - nS} are masked off, then the warp reconverges. Cost ≈ the slower path, not the average.</> : nS === 32 ? <>All lanes take the branch: no divergence, full warp efficiency.</> : <>No lane takes the branch: the warp skips it.</>}</p></div>
        <div className="rounded-lg bg-surface-2 p-3"><div className="label">Branch-free transition</div><p className="mt-1 text-ink-2">The state update (<Code>ns = s + (toE|toI|toR)</Code>) is predicated arithmetic: all 32 lanes execute identical instructions whatever their state — no divergence cost.</p></div>
      </div>
      <p className="mt-3 text-xs leading-relaxed text-mute">SIMT: the 32 threads of a warp share one instruction stream; the hardware tracks an active mask per instruction. V6 adds <Code>skip_rng</Code> (skip the draw when a location’s infection probability is exactly 0) — it reduces work inside the divergent branch. Lane-to-state mix changes every day, so how much divergence occurs is data-dependent (illustration uses a fixed pseudo-random lane pattern).</p>
    </div>
  )
}

/* ───────── 8. Atomics ───────── */

function AtomicsViz() {
  const [n, setN] = useState(100000)
  const [B, setB] = useState(256)
  const blocks = Math.ceil(n / B)
  const row = (label: string, value: number, color: string, note: string) => (
    <div className="grid grid-cols-[110px_1fr_auto] items-center gap-3 text-xs"><span className="text-ink-2">{label}</span>
      <div className="h-5 overflow-hidden rounded bg-surface-3"><div className="h-full rounded transition-all duration-500" style={{ width: `${Math.max(1.5, (Math.log10(value + 1) / Math.log10(n + 1)) * 100)}%`, background: color }} /></div>
      <span className="num text-right"><b>{value.toLocaleString()}</b> <span className="text-mute">{note}</span></span></div>
  )
  return (
    <div>
      <div className="mb-3 flex flex-wrap gap-x-6 gap-y-2">
        <Segmented mono label="Agents N" value={n} onChange={setN} options={[10000, 100000, 1000000, 5000000].map((v) => ({ id: v, label: v >= 1e6 ? v / 1e6 + 'M' : v / 1e3 + 'k' }))} />
        <Segmented mono label="Block size" value={B} onChange={setB} options={[64, 128, 256, 512, 1024].map((v) => ({ id: v, label: v }))} />
      </div>
      <div className="space-y-2.5">
        {row('V5 · global', n, C.coral, 'atomics onto 4 addresses (S/E/I/R counters)')}
        {row('V6 E1 · global', 4 * blocks, C.teal, `≤ 4 per block × ${blocks.toLocaleString()} blocks`)}
        {row('V6 E1 · shared', 0, C.glacier, '')}
      </div>
      <p className="mt-2 text-[11px] text-mute">Upper bounds from the kernel’s structure (one atomic per agent in V5; ≤4 per block after warp ballot + shared-memory aggregation in V6 E1). Per-warp shared atomics (≤4 per warp) are on-chip and not counted in the bars. Actual counts depend on how many states are present in a block.</p>
      <div className="mt-3 rounded-lg bg-surface-2 p-3 text-xs leading-relaxed text-ink-2">
        <b>Why it matters:</b> in V5 every agent adds to one of only four global words, so all N atomics contend on four cache lines. <b>Not aggregated:</b> the location tallies <Code>nin[home]</Code>/<Code>nin[work]</Code> (only infectious agents write, to scattered addresses — warp neighbours almost never share a location, so warp aggregation would find no duplicates; the V6 design notes record this and leave it unimplemented).
        <br />Atomics on integers are exact and order-independent, which is why the aggregated and non-aggregated versions produce identical counts.
      </div>
    </div>
  )
}

/* ───────── 9. Reductions ───────── */

function ReductionViz() {
  const [lvl, setLvl] = useState(0)
  const levels = [
    { t: 'Lane predicate', d: 'Each of 32 lanes evaluates valid && ns == k (k = S,E,I,R).', n: '32 lanes', c: C.slate },
    { t: 'Warp: __ballot_sync + __popc', d: 'One instruction builds a 32-bit mask of lanes with state k; __popc counts the bits. No atomics, no memory traffic.', n: '1 count / warp / state', c: C.lavender },
    { t: 'Block: shared-memory atomicAdd', d: 'Lane 0 of each warp adds its popcount to sc[k] in shared memory (__shared__ uint32_t sc[4]); __syncthreads() brackets the phase.', n: '4 words in smem', c: C.glacier },
    { t: 'Grid: global atomicAdd', d: 'Threads 0–3 add the block totals into counts[4·day + k] — at most 4 global atomics per block.', n: '≤ 4 / block', c: C.teal },
  ]
  return (
    <div>
      <div className="mb-3 flex flex-wrap gap-1.5">{levels.map((l, i) => <button key={l.t} onClick={() => setLvl(i)} className={`rounded-md border px-2.5 py-1.5 text-xs transition ${i === lvl ? 'border-teal-500 bg-teal-50 font-semibold text-teal-700' : 'border-line text-mute hover:border-line-2'}`}>{i + 1}. {l.t.split(':')[0]}</button>)}</div>
      <svg viewBox="0 0 560 140" className="w-full" role="img" aria-label="Hierarchical reduction tree from lanes to global memory">
        {levels.map((l, i) => { const w = [520, 360, 200, 80][i], x = (560 - w) / 2, y = 8 + i * 32; return <g key={i} opacity={i <= lvl ? 1 : 0.25} style={{ transition: 'opacity .3s' }}><rect x={x} y={y} width={w} height={24} rx={6} fill={l.c} /><text x={280} y={y + 16} textAnchor="middle" fontSize={11} fill="#fff" fontWeight={600}>{l.n}</text></g> })}
      </svg>
      <div className="mt-2 rounded-lg bg-surface-2 p-3 text-xs leading-relaxed text-ink-2"><b>{levels[lvl].t}.</b> {levels[lvl].d}</div>
      <p className="mt-3 text-xs leading-relaxed text-mute">The same idea at CPU scale is OpenMP’s <Code>reduction(+: cs,ce,ci,cr)</Code> (V2 default) and OpenACC’s reduction clause (V4): each worker accumulates privately and partials are combined once. All reductions in CityEpi-GPU are over <b>integers</b>, so the result is bit-identical for any combining order — the reason the recorded daily checksums match across backends.</p>
    </div>
  )
}

/* ───────── 10. Memory hierarchy ───────── */

function MemoryViz() {
  const tiers = [
    { n: 'Registers', d: 'Per-thread. Recorded V6 kernels use 28 (location kernel) and 26–34 (agent kernel) registers per thread, 0 B spilled to local memory; occupancy 100% (4 blocks/SM at 256 threads).', c: C.teal, w: 30 },
    { n: 'Shared memory', d: 'Per-block, on-chip. V6 E1 uses 16 B (the 4-word state-count accumulator) — recorded as smem=16B in the kernel info; all other variants use none.', c: C.glacier, w: 50 },
    { n: 'Global (device DRAM)', d: 'All agent arrays (state, timer, home/work ids), location tables (prob, tally) and the daily counts array live here: 14.6 GiB on the recorded Tesla T4. Reads are coalesced for st/tm; hl/wl→pr[] and nin[] accesses are gathers/scatters at random locations.', c: C.lavender, w: 75 },
    { n: 'Host memory (PCIe)', d: 'Population is uploaded once (h2d) and per-day counts come back (d2h). Recorded 100k-agent V6 run: h2d ≈ 0.6 ms, d2h ≈ 0.09 ms vs a 3–10 ms 100-day loop (V6 variants) — transfers are not the bottleneck at this size.', c: C.slate, w: 100 },
  ]
  const [i, setI] = useState(2)
  return (
    <div>
      <div className="space-y-1.5">{tiers.map((t, k) => (
        <button key={t.n} onClick={() => setI(k)} className="block w-full text-left" aria-pressed={k === i}>
          <div className="flex items-center gap-3"><div className="h-8 rounded-md px-3 text-xs font-semibold leading-8 text-white transition-all duration-300" style={{ width: `${t.w}%`, background: t.c, outline: k === i ? `2px solid ${C.ink}` : 'none', outlineOffset: 2 }}>{t.n}</div>{k === 0 && <span className="text-[10px] text-mute">smallest · fastest</span>}{k === 3 && <span className="text-[10px] text-mute">largest · slowest</span>}</div>
        </button>))}</div>
      <div className="mt-3 rounded-lg bg-surface-2 p-3 text-xs leading-relaxed text-ink-2"><b>{tiers[i].n}.</b> {tiers[i].d}</div>
      <p className="mt-2 text-[11px] text-mute">Only values present in the recorded T4 benchmark artifacts are quoted. Cache sizes and bandwidth are not recorded and are not asserted.</p>
    </div>
  )
}

/* ───────── concept registry ───────── */

interface Concept {
  id: string; title: string; ver: string; blurb: string; viz: () => ReactNode
  impl: { where: string; what: string }[]; takeaway: string
}

const CONCEPTS: Concept[] = [
  { id: 'seq', title: 'Sequential CPU execution', ver: 'V0', blurb: 'Baseline: one thread, one agent at a time.', viz: SequentialViz,
    impl: [{ where: 'src/common/simulation.cpp, contact.cpp, transitions.cpp', what: 'V0 runs exposure, transition and counting as separate passes over all agents, calling rand01() (3 chained mixes) for each draw.' }],
    takeaway: 'V0 is the source of truth: every other backend is checked against its daily S/E/I/R counts and checksum.' },
  { id: 'ilp', title: 'Instruction-level parallelism', ver: 'V1', blurb: 'Same thread, shorter dependency chains and fewer passes.', viz: IlpViz,
    impl: [{ where: 'src/v1_ilp/v1_simulation.cpp, include/rng_inline.hpp', what: 'Fused single pass; per-location probability table; seed stage hoisted, agent stage shared by both draws; branchless transition and counters.' }],
    takeaway: 'Measured V1 ≈ 1.7–2.4× V0 across the recorded runs (M1 and Kaggle Xeon). The gain mixes ILP with fewer instructions/passes — no per-change ablation was run, so it is not attributed to ILP alone.' },
  { id: 'omp', title: 'OpenMP thread-level parallelism', ver: 'V2', blurb: 'Divide agents across cores.', viz: OpenMpViz,
    impl: [{ where: 'src/v2_openmp/v2_simulation.cpp:46,53', what: '#pragma omp parallel reduction(+: cs,ce,ci,cr) + omp for schedule(runtime); schedule/chunk set by omp_set_schedule.' }, { where: 'v2_simulation.cpp:74-79', what: 'Atomic variant: #pragma omp atomic on the shared tally (the slow alternative).' }],
    takeaway: 'Counter-based RNG + integer sums make output independent of thread count and schedule.' },
  { id: 'simd', title: 'SIMD vector processing', ver: 'V3', blurb: 'Process 16 agents per 128-bit NEON instruction stream.', viz: SimdViz,
    impl: [{ where: 'src/v3_simd/v3_simulation.cpp:7,172', what: 'NEON only compiles on aarch64; otherwise use_simd is forced off (scalar fallback).' }, { where: 'src/v3_simd/v3_hybrid.cpp:50 (block16)', what: 'Scalar exposure per lane, NEON branchless transition and counts, scalar scatter.' }],
    takeaway: 'SIMD helps only where lanes do uniform arithmetic; this workload is dominated by RNG and scatter, so full NEON lost to V1.' },
  { id: 'acc', title: 'OpenACC accelerator offloading', ver: 'V4', blurb: 'Directive-based GPU offload.', viz: OpenAccViz,
    impl: [{ where: 'src/v4_openacc/v4_simulation.cpp:89,172,180,202', what: 'enter data / parallel loop present(...) / reduction(+) / atomic update / exit data.' }],
    takeaway: 'Same algorithm as V1 with pragmas; the compiler chooses the GPU mapping. Measured on Kaggle T4 with NVHPC.' },
  { id: 'cuda', title: 'CUDA grid / block / thread hierarchy', ver: 'V5 · V6', blurb: 'Thread per agent, blocks scheduled across SMs.', viz: CudaGridViz,
    impl: [{ where: 'src/v5_cuda/v5_simulation.cu:47,58', what: 'location_prob_kernel (thread per location) and agent_step_kernel (thread per agent), a = blockIdx.x·blockDim.x + threadIdx.x with an a<n guard.' }, { where: 'src/v6_cuda/v6_simulation.cu:65-146', what: 'Templated on block size B; day index in a device counter so a CUDA Graph can replay launches.' }],
    takeaway: 'Block size changes launch shape only (RNG depends on seed, agent, day, slot), so output is independent of it.' },
  { id: 'simt', title: 'SIMT and warp execution', ver: 'V5 · V6', blurb: '32 threads, one instruction stream.', viz: SimtViz,
    impl: [{ where: 'v6_simulation.cu:101 (if s == S)', what: 'Only susceptible agents draw random numbers — the divergent region. Transition arithmetic is predicated, not branched.' }, { where: 'v6_simulation.cu (skip_rng, pred_loads)', what: 'E3 options that trim work inside that branch.' }],
    takeaway: 'Divergence is data-dependent; the recorded E3 micro-optimisations were small (all three combined: ≈14% faster than V6_base at 10k, ≈5% at 100k).' },
  { id: 'atomic', title: 'Synchronisation and atomics', ver: 'V5 · V6', blurb: 'Safe concurrent updates, at a price.', viz: AtomicsViz,
    impl: [{ where: 'v5_simulation.cu:80-83', what: 'atomicAdd(&counts[ns],1) for every agent; atomicAdd(&nin[h|w]) for infectious agents.' }, { where: 'v6_simulation.cu:128-142', what: 'AGG path: shared sc[4], __syncthreads(), ballot/popc, ≤4 global atomics per block.' }],
    takeaway: 'Reducing 100k contended atomics to a few hundred is the single largest recorded V6 gain at 100k agents (≈3.1× over V5 in the same run).' },
  { id: 'reduce', title: 'Parallel reductions', ver: 'V2 · V4 · V6', blurb: 'Combine partial results hierarchically.', viz: ReductionViz,
    impl: [{ where: 'v2_simulation.cpp:46; v4_simulation.cpp:181; v6_simulation.cu:129-139', what: 'OpenMP reduction clause; OpenACC reduction clause; manual lane→warp→block→grid reduction in CUDA.' }],
    takeaway: 'Integer reductions are associative and exact: parallel order never changes the answer.' },
  { id: 'mem', title: 'GPU memory hierarchy', ver: 'V5 · V6', blurb: 'Registers → shared → global → host.', viz: MemoryViz,
    impl: [{ where: 'kaggle_v6/v6_benchmark.csv header (# kernel_info)', what: 'Registers, local-memory spill, shared-memory bytes and occupancy per kernel variant.' }],
    takeaway: 'Per-day host traffic is only the 16-byte counter array; the population stays resident on the device.' },
]

export default function ArchitectureExplorer() {
  const [id, setId] = useState(CONCEPTS[0].id)
  const c = CONCEPTS.find((x) => x.id === id)!
  const Viz = c.viz
  return (
    <div className="space-y-5">
      <Notice tone="info"><b>V7/V8 (MPI) are not implemented</b> — distributed execution remains future scope. V4–V6 diagrams describe code that was compiled and run on a Kaggle Tesla T4; this Mac has no CUDA device, so nothing on this tab executes on a GPU.</Notice>
      <div className="grid gap-5 lg:grid-cols-[260px_1fr]">
        <nav aria-label="PAGP concepts" className="card self-start p-2">
          <ol className="grid grid-cols-2 gap-0.5 lg:grid-cols-1">
            {CONCEPTS.map((k, n) => (
              <li key={k.id}><button onClick={() => setId(k.id)} aria-current={k.id === id} className={`flex w-full items-start gap-2.5 rounded-lg px-2.5 py-2 text-left transition ${k.id === id ? 'bg-teal-50 text-teal-700' : 'text-ink-2 hover:bg-surface-2'}`}>
                <span className="num mt-px text-[11px] text-mute">{String(n + 1).padStart(2, '0')}</span>
                <span className="min-w-0"><span className="block text-xs font-semibold leading-tight">{k.title}</span><span className="num text-[10px] text-mute">{k.ver}</span></span>
              </button></li>))}
          </ol>
        </nav>
        <div key={c.id} className="space-y-4 animate-fade-up">
          <Card title={c.title} sub={`${c.ver} · ${c.blurb}`}><Viz /></Card>
          <div className="grid gap-4 md:grid-cols-2">
            <Card title="In CityEpi-GPU">
              <ul className="space-y-2.5 text-xs">{c.impl.map((m) => <li key={m.where}><div className="num text-[11px] text-teal-700">{m.where}</div><div className="mt-0.5 leading-relaxed text-ink-2">{m.what}</div></li>)}</ul>
            </Card>
            <Card title="Takeaway"><p className="text-xs leading-relaxed text-ink-2">{c.takeaway}</p></Card>
          </div>
        </div>
      </div>
    </div>
  )
}
