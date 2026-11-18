import { Fragment, useMemo, useState } from 'react'
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import type { BenchRow, Benchmarks } from '../../api/types'
import { Badge, Card, EmptyState, Notice, Segmented, axis, grid, legendStyle, tooltipStyle } from '../ui'
import { compact, nf, secs, x } from '../../lib/format'
import { BACKEND, C } from '../../lib/theme'
import { improvement, rate, throughput } from '../../lib/perf'
import type { M1V2Row, M1V3Row, Perf } from '../../lib/perf'

/* A normalised row from any recorded run. `null` = not recorded (never zero-filled). */
interface Row { agents: number; backend: string; kernel: number; e2e: number | null; h2d: number | null; d2h: number | null; cv: number | null; speedup: number | null; identical: boolean | null }
interface Run { id: string; label: string; short: string; hw: string; compiler: string; flags: string; days: number | null; reps: number | null; file: string; rows: Row[]; caveats: string[] }

const pos = (v: number | null | undefined) => (v != null && v > 0 ? v : null)

function fromBench(rows: BenchRow[]): Row[] {
  return rows.map((r) => ({ agents: r.agents, backend: r.backend, kernel: r.kernel_median_s, e2e: pos(r.e2e_median_s), h2d: pos(r.h2d_median_s), d2h: pos(r.d2h_median_s),
    cv: r.kernel_cv_pct ?? null, speedup: r.kernel_speedup_v0 ?? null, identical: (r.identical ?? r.identical_v0) == null ? null : (r.identical ?? r.identical_v0) === 'yes' }))
}
function fromM1(rows: M1V3Row[]): Row[] {
  return rows.map((r) => ({ agents: r.agents, backend: r.backend, kernel: r.median_s, e2e: null, h2d: null, d2h: null, cv: r.cv_pct, speedup: r.speedup_v0, identical: r.identical === 'yes' }))
}

function buildRuns(b: Benchmarks, p: Perf): Run[] {
  const runs: Run[] = []
  const m1 = p.apple_m1
  const envText = m1.env.v3 ?? ''
  const cpu = envText.split('\n').find((l) => l.includes('Apple')) ?? 'Apple M1'
  if (m1.v3_hybrid) runs.push({
    id: 'm1', label: 'Run A · Apple M1 · CPU (V0–V3)', short: 'Apple M1', hw: `${cpu} · ${m1.v3_hybrid.meta._max_threads ?? '8'} cores`,
    compiler: envText.split('\n').find((l) => l.toLowerCase().includes('clang')) ?? 'Homebrew clang', flags: envText.split('\n').find((l) => l.startsWith('flags')) ?? '',
    days: m1.v3_hybrid.meta._days ? +m1.v3_hybrid.meta._days : null, reps: m1.v3_hybrid.meta._reps ? +m1.v3_hybrid.meta._reps : null, file: m1.v3_hybrid.file, rows: fromM1(m1.v3_hybrid.rows),
    caveats: ['Local CPU run: no GPU backends exist on this machine.', 'V2_4T = OpenMP with 4 threads.', 'V3_neon is the complete NEON implementation; V3_hybrid keeps exposure scalar.'],
  })
  const k4 = p.kaggle_v4.results
  if (k4) runs.push({
    id: 'k4', label: 'Run B · Kaggle T4 · OpenACC (V4) run', short: 'Kaggle · V4 run', hw: `${k4.meta.gpu_model ?? 'Tesla T4'} (accelerator) + host CPU of the notebook`,
    compiler: k4.meta.compiler ?? 'NVHPC', flags: k4.meta.flags ?? '', days: k4.meta._days ? +k4.meta._days : null, reps: k4.meta._repetitions ? +k4.meta._repetitions : null, file: k4.file, rows: fromBench(k4.rows),
    caveats: ['CPU build flags record openmp=OFF: the V2_maxT row is NOT a multithreaded measurement in this run (it is ≈ V2_1T).', 'The row labelled V3_neon ran on an x86 host: NEON is aarch64-only, so this is the scalar fallback, not NEON.'],
  })
  const m5 = b.v5.meta
  runs.push({
    id: 'k5', label: 'Run C · Kaggle T4 · CUDA V5 run', short: 'Kaggle · V5 run', hw: `${m5.gpu_model ?? 'Tesla T4'} · ${m5.cpu_model ?? ''} (${m5.cpu_logical_cores ?? '?'} logical cores)`,
    compiler: m5.cuda_compiler ?? 'nvcc', flags: m5.flags ?? '', days: m5._days ? +m5._days : null, reps: m5._reps ? +m5._reps : null, file: 'bench/results/kaggle_v5/v5_benchmark.csv', rows: fromBench(b.v5.rows),
    caveats: ['CPU rows built with OpenMP ON; V2_maxT used 4 threads (the notebook has 4 logical cores).', 'The row labelled V3_simd ran on an x86 host: NEON is aarch64-only, so this is the scalar fallback.'],
  })
  const m6 = b.v6.meta
  const v6def = b.v6_all_scenarios.rows.filter((r) => r.scenario === 'default')
  const v6best: BenchRow[] = []
  for (const n of [...new Set(v6def.map((r) => r.agents))]) {
    const g = v6def.filter((r) => r.agents === n)
    v6best.push(...g.filter((r) => !r.backend.startsWith('V6')))
    const vs = g.filter((r) => r.backend.startsWith('V6'))
    const base = vs.find((r) => r.backend === 'V6_base'); if (base) v6best.push(base)
    const best = [...vs].sort((a, c) => a.kernel_median_s - c.kernel_median_s)[0]; if (best) v6best.push({ ...best, backend: 'V6_best' })
  }
  runs.push({
    id: 'k6', label: 'Run D · Kaggle T4 · CUDA V6 run', short: 'Kaggle · V6 run', hw: `${m6.gpu_model ?? 'Tesla T4'} · ${m6.cpu_model ?? ''}`,
    compiler: m6.cuda_compiler ?? 'nvcc', flags: m6.flags ?? '', days: m6._days ? +m6._days : null, reps: m6._reps ? +m6._reps : null, file: 'bench/results/kaggle_v6/v6_benchmark_all.csv', rows: fromBench(v6best),
    caveats: ['V0 and V5 are re-timed inside this run; V6_best is the fastest of the recorded V6 variants at that size (selected after the fact).', 'Default workload (β = 0.3); low/high workloads are in the CUDA deep-dive tab.'],
  })
  return runs
}

const BCOL = (b: string) => BACKEND[b] ?? (b.startsWith('V6') ? C.teal : b.startsWith('V3') ? C.amber : b.startsWith('V2') ? C.glacier : b === 'V4' ? C.coral : C.slate)

/* ───────── component ───────── */

export default function BenchmarkExplorer({ bench, perf }: { bench: Benchmarks; perf: Perf }) {
  const runs = useMemo(() => buildRuns(bench, perf), [bench, perf])
  return (
    <div className="space-y-5">
      <Notice><b>These are four separate benchmark runs on different machines, compilers and builds.</b> Each run has its own V0 baseline, so a speedup is only meaningful <i>inside</i> its run. Nothing below is a controlled head-to-head across runs, and nothing is re-executed here.</Notice>
      <Provenance runs={runs} />
      <Overview runs={runs} />
      <Scaling runs={runs} />
      <KernelVsE2E runs={runs} />
      <OpenMp p={perf} />
      <Simd p={perf} />
      <OpenAcc runs={runs} />
      <V5V6 b={bench} />
    </div>
  )
}

function Provenance({ runs }: { runs: Run[] }) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {runs.map((r) => (
        <Card key={r.id} title={r.label} sub={<span className="num">{r.file}</span>} hover>
          <dl className="grid grid-cols-[88px_1fr] gap-x-3 gap-y-1.5 text-xs">
            <dt className="text-mute">Hardware</dt><dd>{r.hw}</dd>
            <dt className="text-mute">Compiler</dt><dd>{r.compiler}</dd>
            <dt className="text-mute">Flags</dt><dd className="break-words font-mono text-[10px] leading-snug text-ink-2">{r.flags || '—'}</dd>
            <dt className="text-mute">Protocol</dt><dd>{r.days ?? '?'} simulated days · {r.reps ?? '?'} repetitions (median) · sizes {[...new Set(r.rows.map((q) => q.agents))].sort((a, b) => a - b).map(compact).join(', ')}</dd>
          </dl>
          <ul className="mt-3 list-disc space-y-1 pl-4 text-[11px] leading-relaxed text-mute">{r.caveats.map((c) => <li key={c}>{c}</li>)}</ul>
        </Card>
      ))}
    </div>
  )
}

const ROWS: { label: string; ver: string; pick: Record<string, string> }[] = [
  { label: 'V0 · sequential baseline', ver: 'V0', pick: { m1: 'V0', k4: 'V0', k5: 'V0', k6: 'V0' } },
  { label: 'V1 · ILP scalar', ver: 'V1', pick: { m1: 'V1', k4: 'V1', k5: 'V1' } },
  { label: 'V2 · OpenMP (max threads of run)', ver: 'V2', pick: { m1: 'V2_4T', k4: 'V2_maxT', k5: 'V2_maxT' } },
  { label: 'V3 · complete NEON / SIMD row', ver: 'V3', pick: { m1: 'V3_neon', k4: 'V3_neon', k5: 'V3_simd' } },
  { label: 'V3 · hybrid (NEON transition)', ver: 'V3', pick: { m1: 'V3_hybrid' } },
  { label: 'V4 · OpenACC (T4)', ver: 'V4', pick: { k4: 'V4' } },
  { label: 'V5 · naive CUDA (T4)', ver: 'V5', pick: { k5: 'V5', k6: 'V5' } },
  { label: 'V6 · optimised CUDA — base', ver: 'V6', pick: { k6: 'V6_base' } },
  { label: 'V6 · fastest recorded variant', ver: 'V6', pick: { k6: 'V6_best' } },
]

function Overview({ runs }: { runs: Run[] }) {
  const sizes = useMemo(() => [...new Set(runs.flatMap((r) => r.rows.map((q) => q.agents)))].sort((a, b) => a - b), [runs])
  const [n, setN] = useState(100000)
  const [metric, setMetric] = useState<'kernel' | 'e2e'>('kernel')
  const get = (r: Run, b?: string) => (b ? r.rows.find((q) => q.agents === n && q.backend === b) : undefined)
  const [sel, setSel] = useState(runs.length > 3 ? 'k5' : runs[0].id)
  const run = runs.find((r) => r.id === sel) ?? runs[0]
  const chart = run.rows.filter((q) => q.agents === n)
  const val = (q: Row) => (metric === 'e2e' ? q.e2e : q.kernel)
  return (
    <Card title="V0 → V6 at a glance" sub="Median time for the whole simulation. Each cell: time · speedup over the V0 row of the SAME run. “—” means that backend was not part of that run." right={<Segmented mono label="Agents" value={n} onChange={setN} options={sizes.map((s) => ({ id: s, label: compact(s) }))} />}>
      <div className="overflow-x-auto">
        <table className="tbl tbl-sm text-xs">
          <thead><tr className="text-left"><th>Implementation</th>{runs.map((r) => <th key={r.id} className="pr-3">{r.short}</th>)}</tr></thead>
          <tbody>{ROWS.map((row) => (
            <tr key={row.label}><td className="pr-4 font-medium">{row.label}</td>{runs.map((r) => {
              const q = get(r, row.pick[r.id]); const mk = r.rows.find((z) => z.backend === 'V0' && z.agents === n)
              const sp = q && mk ? mk.kernel / q.kernel : null     // recomputed from this run's own V0 median
              return <td key={r.id} className="num pr-3">{q ? <><span>{secs(q.kernel)}</span> <span className={sp != null && sp < 1 ? 'text-coral-deep' : 'text-mute'}>· {x(sp)}</span></> : <span className="text-mute/60">—</span>}</td>
            })}</tr>))}
          </tbody>
        </table>
      </div>
      <p className="mt-2 text-[11px] text-mute">Speedups below 1× (red) mean slower than that run’s V0. V7/V8 (MPI) are not implemented. See each run’s caveats above before reading any row — in particular, the V2 / V3 rows of the V4 and V5 runs.</p>

      <div className="mt-5 flex flex-wrap items-center gap-x-6 gap-y-2">
        <Segmented label="Run" value={sel} onChange={setSel} options={runs.map((r) => ({ id: r.id, label: r.short }))} />
        <Segmented label="Time" value={metric} onChange={setMetric} options={[{ id: 'kernel' as const, label: 'Kernel / day loop' }, { id: 'e2e' as const, label: 'End-to-end' }]} />
      </div>
      {chart.filter((q) => val(q) != null).length === 0 ? <EmptyState title="Not recorded">This run has no {metric === 'e2e' ? 'end-to-end' : 'kernel'} timing for {compact(n)} agents.</EmptyState> : (
        <div className="mt-3 h-[260px]"><ResponsiveContainer>
          <BarChart data={chart.filter((q) => val(q) != null)} margin={{ left: 0, right: 10 }}>
            <CartesianGrid {...grid} vertical={false} /><XAxis dataKey="backend" {...axis} interval={0} fontSize={10} />
            <YAxis {...axis} scale="log" domain={[(m: number) => m / 2, (m: number) => m * 1.6]} allowDataOverflow tickFormatter={(v) => secs(v)} width={78} />
            <Tooltip {...tooltipStyle} formatter={(_v: any, _n, pr) => [`${secs(val(pr.payload))}${pr.payload.speedup != null ? ` · ${x(pr.payload.speedup)} vs V0 (kernel)` : ''}`, metric === 'e2e' ? 'end-to-end median' : 'kernel median']} />
            <Bar dataKey={(q: Row) => val(q)} radius={[4, 4, 0, 0]} isAnimationActive={false}>{chart.map((q) => <Cell key={q.backend} fill={BCOL(q.backend)} />)}</Bar>
          </BarChart></ResponsiveContainer></div>
      )}
      <p className="mt-1 text-[11px] text-mute">Log scale. CPU backends have no transfers, so their end-to-end time equals the kernel time and is only recorded for GPU rows in the Kaggle CSVs.</p>
    </Card>
  )
}

function Scaling({ runs }: { runs: Run[] }) {
  const [sel, setSel] = useState(runs.find((r) => r.id === 'k5')?.id ?? runs[0].id)
  const [metric, setMetric] = useState<'time' | 'rate'>('time')
  const run = runs.find((r) => r.id === sel)!
  const sizes = [...new Set(run.rows.map((q) => q.agents))].sort((a, b) => a - b)
  const backs = [...new Set(run.rows.map((q) => q.backend))]
  const data = sizes.map((a) => { const o: Record<string, number | null> = { agents: a }; for (const q of run.rows.filter((z) => z.agents === a)) o[q.backend] = metric === 'time' ? q.kernel : throughput(a, run.days, q.kernel); return o })
  return (
    <Card title="Population-size scaling" sub={`${run.label} · log–log. Throughput = agents × ${run.days ?? '?'} days ÷ kernel median.`}
      right={<div className="flex flex-wrap gap-3"><Segmented label="Run" value={sel} onChange={setSel} options={runs.map((r) => ({ id: r.id, label: r.short }))} /><Segmented value={metric} onChange={setMetric} options={[{ id: 'time' as const, label: 'Time' }, { id: 'rate' as const, label: 'Throughput' }]} /></div>}>
      <div className="h-[300px]"><ResponsiveContainer>
        <LineChart data={data} margin={{ left: 0, right: 14 }}>
          <CartesianGrid {...grid} /><XAxis dataKey="agents" {...axis} scale="log" type="number" domain={['dataMin', 'dataMax']} ticks={sizes} tickFormatter={compact} />
          <YAxis {...axis} scale="log" domain={['auto', 'auto']} tickFormatter={(v) => (metric === 'time' ? secs(v) : rate(v))} width={74} />
          <Tooltip {...tooltipStyle} formatter={(v: any) => (metric === 'time' ? secs(v) : `${rate(v)} agent-days/s`)} labelFormatter={(a) => `${nf(a as number)} agents`} /><Legend wrapperStyle={legendStyle} />
          {backs.map((b) => <Line key={b} dataKey={b} stroke={BCOL(b)} strokeWidth={b.startsWith('V5') || b.startsWith('V4') || b.startsWith('V6') ? 2.8 : 1.6} dot={{ r: 3 }} connectNulls isAnimationActive={false} />)}
        </LineChart></ResponsiveContainer></div>
      <p className="mt-2 text-[11px] text-mute">CPU backends scale ≈ linearly in N (slope 1 on log–log). GPU backends are flatter at small N because per-day launch/synchronisation latency dominates; they approach linear scaling only at larger N.</p>
    </Card>
  )
}

function KernelVsE2E({ runs }: { runs: Run[] }) {
  const gpu = runs.filter((r) => r.id !== 'm1')
  return (
    <Card title="Kernel time vs end-to-end time" sub="Kernel = the 100-day loop with data already resident (includes the count read-back). End-to-end additionally includes allocation, host↔device copies and (V6 graph rows) graph build.">
      <div className="overflow-x-auto"><table className="tbl tbl-sm text-xs">
        <thead><tr className="text-left"><th>Run</th><th>Backend</th><th className="text-right">Agents</th><th className="text-right">Kernel</th><th className="text-right">End-to-end</th><th className="text-right">H2D</th><th className="text-right">D2H</th><th className="text-right">Overhead</th></tr></thead>
        <tbody>{gpu.flatMap((r) => r.rows.filter((q) => ['V4', 'V5', 'V6_base', 'V6_best'].includes(q.backend) && q.e2e != null && [100000, 1000000].includes(q.agents)).map((q) => (
          <tr key={r.id + q.backend + q.agents}><td className="pr-3 text-mute">{r.short}</td><td className="pr-3 font-medium">{q.backend}</td><td className="num pr-3 text-right">{compact(q.agents)}</td><td className="num pr-3 text-right">{secs(q.kernel)}</td><td className="num pr-3 text-right">{secs(q.e2e)}</td><td className="num pr-3 text-right">{secs(q.h2d)}</td><td className="num pr-3 text-right">{secs(q.d2h)}</td>
            <td className="num text-right">{nf(improvement(q.e2e, q.kernel), 1)}%</td></tr>)))}</tbody>
      </table></div>
      <p className="mt-2 text-[11px] text-mute">Overhead = share of end-to-end time spent outside the kernel/day loop = (e2e − kernel) ÷ e2e. A V5 row inside the V6 run has no end-to-end timing recorded and is omitted. CPU rows have no separate end-to-end measurement.</p>
    </Card>
  )
}

/* ───────── V2 OpenMP ───────── */

const CFG: { key: string; label: string; match: (r: M1V2Row) => boolean; color: string }[] = [
  { key: 'static', label: 'static · private histograms', match: (r) => r.sched === 'static' && r.reduce === 'local', color: C.teal },
  { key: 'dynamic', label: 'dynamic(1024) · private', match: (r) => r.sched === 'dynamic', color: C.glacier },
  { key: 'guided', label: 'guided · private', match: (r) => r.sched === 'guided', color: C.lavender },
  { key: 'atomic', label: 'static · shared + atomic', match: (r) => r.reduce === 'atomic', color: C.coral },
]

function OpenMp({ p }: { p: Perf }) {
  const v2 = p.apple_m1.v2
  const sizes = useMemo(() => [...new Set((v2?.rows ?? []).map((r) => r.agents))].sort((a, b) => a - b), [v2])
  const [n, setN] = useState(1000000)
  const [m, setM] = useState<'speedup' | 'eff' | 'time'>('speedup')
  if (!v2) return <Card title="OpenMP scaling"><EmptyState title="v2_results.csv not found" /></Card>
  const rows = v2.rows.filter((r) => r.agents === n && r.backend === 'V2')
  const v0 = v2.rows.find((r) => r.agents === n && r.backend === 'V0'), v1 = v2.rows.find((r) => r.agents === n && r.backend === 'V1')
  const threads = [...new Set(rows.map((r) => r.threads))].sort((a, b) => a - b)
  const data = threads.map((t) => { const o: Record<string, number | null> = { threads: t }; for (const c of CFG) { const r = rows.find((z) => z.threads === t && c.match(z)); o[c.key] = r ? (m === 'speedup' ? r.speedup_v0 : m === 'eff' ? r.efficiency : r.median_s) : null } return o })
  const best = [...rows].sort((a, b) => a.median_s - b.median_s)[0]
  return (
    <Card title="OpenMP thread scaling and scheduling (V2)" sub={`Apple M1 · ${v2.meta._reps ?? '?'} reps · ${v2.meta._days ?? '?'} days · ${v2.file}. Efficiency = t(V2, 1 thread) ÷ (T × t(V2, T)), as recorded.`}
      right={<div className="flex flex-wrap gap-3"><Segmented mono label="Agents" value={n} onChange={setN} options={sizes.map((s) => ({ id: s, label: compact(s) }))} /><Segmented value={m} onChange={setM} options={[{ id: 'speedup' as const, label: 'Speedup vs V0' }, { id: 'eff' as const, label: 'Efficiency' }, { id: 'time' as const, label: 'Time' }]} /></div>}>
      <div className="h-[290px]"><ResponsiveContainer>
        <LineChart data={data} margin={{ left: 0, right: 14 }}>
          <CartesianGrid {...grid} /><XAxis dataKey="threads" {...axis} type="number" ticks={threads} domain={['dataMin', 'dataMax']} label={{ value: 'threads', position: 'insideBottomRight', offset: -4, fill: C.axis, fontSize: 11 }} />
          <YAxis {...axis} width={62} tickFormatter={(v) => (m === 'time' ? secs(v) : m === 'eff' ? nf(v, 1) : `${nf(v, 1)}×`)} domain={m === 'eff' ? [0, 1.1] : ['auto', 'auto']} />
          <Tooltip {...tooltipStyle} formatter={(v: any) => (m === 'time' ? secs(v) : m === 'eff' ? nf(v, 2) : x(v))} labelFormatter={(t) => `${t} thread${t === 1 ? '' : 's'}`} /><Legend wrapperStyle={legendStyle} />
          {CFG.map((c) => <Line key={c.key} name={c.label} dataKey={c.key} stroke={c.color} strokeWidth={2.2} dot={{ r: 3 }} connectNulls isAnimationActive={false} />)}
        </LineChart></ResponsiveContainer></div>
      <div className="mt-3 flex flex-wrap gap-2 text-xs">
        {v0 && <Badge color={C.slate}>V0 {secs(v0.median_s)}</Badge>}{v1 && <Badge color={C.lavender}>V1 {secs(v1.median_s)} · {x(v1.speedup_v0)}</Badge>}
        {best && <Badge color={C.teal}>fastest: {best.threads} threads, {best.sched}/{best.reduce} · {secs(best.median_s)} · {x(best.speedup_v0)} vs V0 · {x(best.speedup_v1)} vs V1</Badge>}
      </div>
      <ul className="mt-3 list-disc space-y-1 pl-4 text-[11px] leading-relaxed text-mute">
        <li>Per-thread histograms scale to ~2× V1 and then plateau between 4 and 8 threads (the M1 has 4 performance + 4 efficiency cores, so 8 threads are not 8 equal cores; the scatter into location tallies is memory-bound).</li>
        <li>The shared-atomic variant gets <b>slower</b> as threads are added: concurrent atomic updates to the same cache lines serialise.</li>
        <li>Static, dynamic and guided differ by only a few percent here: work per agent is nearly uniform, so dynamic scheduling mostly adds overhead. Differences of this size are within the run-to-run variability recorded in the other files.</li>
      </ul>
    </Card>
  )
}

/* ───────── V3 SIMD vs scalar ───────── */

function Simd({ p }: { p: Perf }) {
  const h = p.apple_m1.v3_hybrid, s = p.apple_m1.v3
  const sizes = useMemo(() => [...new Set((h?.rows ?? []).map((r) => r.agents))].sort((a, b) => a - b), [h])
  const [n, setN] = useState(1000000)
  if (!h) return null
  const order = ['V0', 'V1', 'V3_scalar', 'V3_neon', 'V3_hybrid_scalar', 'V3_hybrid']
  const rows = order.map((b) => h.rows.find((r) => r.agents === n && r.backend === b)).filter(Boolean) as M1V3Row[]
  const v1 = rows.find((r) => r.backend === 'V1')
  const first = s?.rows.find((r) => r.agents === n && r.backend === 'V3_neon')
  const label: Record<string, string> = { V0: 'V0 baseline', V1: 'V1 scalar ILP', V3_scalar: 'V3 scalar reference', V3_neon: 'V3 complete NEON', V3_hybrid_scalar: 'V3 hybrid · scalar path', V3_hybrid: 'V3 hybrid (NEON transition)' }
  return (
    <Card title="SIMD vs scalar (V3, ARM NEON)" sub={`Apple M1 · ${h.file} · speedup vs V1 recomputed from medians`} right={<Segmented mono label="Agents" value={n} onChange={setN} options={sizes.map((v) => ({ id: v, label: compact(v) }))} />}>
      <div className="h-[240px]"><ResponsiveContainer>
        <BarChart data={rows.map((r) => ({ ...r, name: label[r.backend], vs_v1: v1 ? v1.median_s / r.median_s : null }))} layout="vertical" margin={{ left: 10, right: 30 }}>
          <CartesianGrid {...grid} horizontal={false} /><XAxis type="number" {...axis} tickFormatter={(v) => `${nf(v, 1)}×`} /><YAxis type="category" dataKey="name" {...axis} width={170} fontSize={10} interval={0} />
          <Tooltip {...tooltipStyle} formatter={(v: any, _n, pr) => [`${x(v)} vs V1 · ${secs(pr.payload.median_s)} (CV ${nf(pr.payload.cv_pct, 1)}%)`, 'speed relative to V1']} />
          <Bar dataKey="vs_v1" radius={[0, 4, 4, 0]} isAnimationActive={false}>{rows.map((r) => <Cell key={r.backend} fill={r.backend === 'V1' ? C.lavender : (v1 && r.median_s > v1.median_s) ? C.coral : C.teal} />)}</Bar>
        </BarChart></ResponsiveContainer></div>
      <p className="mt-1 text-[11px] text-mute">Bar &gt; 1× = faster than V1; red = slower than V1.{first && <> The earlier full-NEON measurement (<span className="num">v3_results.csv</span>) gave {x(first.speedup_v1)} of V1 at this size.</>}</p>
      <Notice tone="info"><b>The complete NEON implementation was slower than V1 for this workload.</b> The hot path is dominated by splitmix64 RNG (64-bit multiplies NEON cannot do per lane), data-dependent branching on state and scatter updates to <code>nin[]</code>; vectorising only the arithmetic added widening/packing overhead. Keeping exposure scalar and vectorising only the transition (hybrid) recovers a modest gain. The Kaggle runs’ “V3” rows are x86 scalar fallbacks and say nothing about NEON.</Notice>
    </Card>
  )
}

/* ───────── V4 OpenACC ───────── */

function OpenAcc({ runs }: { runs: Run[] }) {
  const r = runs.find((q) => q.id === 'k4')
  if (!r) return null
  const sizes = [...new Set(r.rows.map((q) => q.agents))].sort((a, b) => a - b)
  const data = sizes.map((n) => { const v0 = r.rows.find((q) => q.agents === n && q.backend === 'V0'), v1 = r.rows.find((q) => q.agents === n && q.backend === 'V1'), v4 = r.rows.find((q) => q.agents === n && q.backend === 'V4')
    return { n, v4, v0, v1, vs0: v0 && v4 ? v0.kernel / v4.kernel : null, vs1: v1 && v4 ? v1.kernel / v4.kernel : null } })
  return (
    <Card title="OpenACC performance (V4)" sub={`${r.hw} · ${r.compiler} · ${r.file}`}>
      <div className="overflow-x-auto"><table className="tbl tbl-sm text-xs">
        <thead><tr className="text-left"><th>Agents</th><th className="text-right">V0 (this run)</th><th className="text-right">V1 (this run)</th><th className="text-right">V4 kernel</th><th className="text-right">V4 e2e</th><th className="text-right">V4 vs V0</th><th className="text-right">V4 vs V1</th><th className="text-right">H2D</th><th className="text-right">D2H</th></tr></thead>
        <tbody>{data.map((d) => <tr key={d.n}><td className="num font-medium">{compact(d.n)}</td><td className="num text-right">{secs(d.v0?.kernel)}</td><td className="num text-right">{secs(d.v1?.kernel)}</td><td className="num text-right">{secs(d.v4?.kernel)}</td><td className="num text-right">{secs(d.v4?.e2e)}</td><td className={`num text-right ${d.vs0 != null && d.vs0 < 1 ? 'text-coral-deep' : ''}`}>{x(d.vs0)}</td><td className={`num text-right ${d.vs1 != null && d.vs1 < 1 ? 'text-coral-deep' : ''}`}>{x(d.vs1)}</td><td className="num text-right">{secs(d.v4?.h2d)}</td><td className="num text-right">{secs(d.v4?.d2h)}</td></tr>)}</tbody>
      </table></div>
      <ul className="mt-3 list-disc space-y-1 pl-4 text-[11px] leading-relaxed text-mute">
        <li>At 10k agents V4 is <b>slower than V0</b> (per-day kernel launches and the reduction/sync cost exceed the tiny amount of work); the GPU only pays off once there is enough parallel work, as the scaling chart shows.</li>
        <li>These ratios use the V4 run’s own V0/V1 rows. They must not be compared with the V5 or V6 runs’ speedups: different notebook sessions, compiler (NVHPC vs nvcc) and CPU build options.</li>
      </ul>
    </Card>
  )
}

/* ───────── V5 vs V6 (same run) ───────── */

function V5V6({ b }: { b: Benchmarks }) {
  const rows = b.v6_all_scenarios.rows.filter((r) => r.scenario === 'default')
  const sizes = [...new Set(rows.map((r) => r.agents))].sort((a, c) => a - c)
  return (
    <Card title="V5 vs V6 — same-run comparison" sub="Both measured inside the V6 benchmark binary (V5 is re-timed in that run), default workload. This is the one GPU comparison the recorded data supports directly.">
      <div className="overflow-x-auto"><table className="tbl tbl-sm text-xs">
        <thead><tr className="text-left"><th>Agents</th><th className="text-right">V5</th><th className="text-right">V6 base</th><th className="text-right">V6 fastest variant</th><th>Variant</th><th className="text-right">vs V5</th><th className="text-right">Time saved vs V5</th></tr></thead>
        <tbody>{sizes.map((n) => {
          const g = rows.filter((r) => r.agents === n), v5 = g.find((r) => r.backend === 'V5'), base = g.find((r) => r.backend === 'V6_base')
          const best = g.filter((r) => r.backend.startsWith('V6')).sort((a, c) => a.kernel_median_s - c.kernel_median_s)[0]
          return <Fragment key={n}><tr><td className="num font-medium">{compact(n)}</td><td className="num text-right">{secs(v5?.kernel_median_s)}</td><td className="num text-right">{secs(base?.kernel_median_s)}</td><td className="num text-right">{secs(best?.kernel_median_s)}</td><td className="max-w-[260px] truncate pr-3 text-mute" title={best?.opts}>{best?.opts}</td><td className="num text-right">{x(best?.kernel_speedup_v5)}</td><td className="num text-right">{nf(improvement(v5?.kernel_median_s, best?.kernel_median_s), 1)}%</td></tr></Fragment>
        })}</tbody>
      </table></div>
      <p className="mt-2 text-[11px] text-mute">“Fastest variant” is chosen after seeing the results among the recorded variants; the deep-dive tab shows every variant and which ones were not helpful. V6_base ≈ V5 by construction (same arithmetic, day index from a device counter).</p>
    </Card>
  )
}
