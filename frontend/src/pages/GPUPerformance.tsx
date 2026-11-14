import { useMemo, useState } from 'react'
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useApi } from '../api/client'
import type { BenchRow, Benchmarks } from '../api/types'
import { Badge, Card, Loaded, Notice, PageHeader, Stat, axis, grid, tooltipStyle } from '../components/ui'
import { compact, nf, secs, x } from '../lib/format'

const BCOL: Record<string, string> = { V0: '#8b9ab8', V1: '#a78bfa', V2_1T: '#4da3ff', V2_maxT: '#38bdf8', V3_simd: '#f5b83d', V5: '#4ad6a0' }

export default function GPUPerformance() {
  const s = useApi<Benchmarks>('/api/benchmarks')
  return (
    <>
      <PageHeader title="GPU Performance" subtitle="Recorded Kaggle Tesla T4 benchmark artifacts for the V5 and V6 CUDA backends versus CPU backends. Nothing is re-run here." />
      <Loaded state={s}>{(d) => <Body d={d} />}</Loaded>
    </>
  )
}

function Body({ d }: { d: Benchmarks }) {
  const sizes = useMemo(() => [...new Set(d.v5.rows.map((r) => r.agents))].sort((a, b) => a - b), [d])
  const [n, setN] = useState(100000)
  const [scn, setScn] = useState('default')
  const v5n = d.v5.rows.filter((r) => r.agents === n)
  const v6rows = d.v6_all_scenarios.rows.filter((r) => r.agents === n && r.scenario === scn)
  const v6v5 = v6rows.find((r) => r.backend === 'V5')
  const best = [...v6rows].filter((r) => r.backend.startsWith('V6')).sort((a, b) => a.kernel_median_s - b.kernel_median_s)[0]
  const base = v6rows.find((r) => r.backend === 'V6_base')
  const v0_5 = v5n.find((r) => r.backend === 'V0')
  const v5r = v5n.find((r) => r.backend === 'V5')
  const m6 = d.v6.meta, m5 = d.v5.meta

  const scaling = sizes.map((a) => {
    const row: Record<string, number> = { agents: a }
    for (const r of d.v5.rows.filter((r) => r.agents === a)) row[r.backend] = r.kernel_median_s
    return row
  })
  const variants = v6rows.filter((r) => r.backend.startsWith('V6')).sort((a, b) => b.kernel_speedup_v0 - a.kernel_speedup_v0)
  const prof = d.v6_profile_all.filter((r) => r.agents === n && r.scenario === scn)
  const allIdentical = [...d.v5.rows, ...d.v6_all_scenarios.rows].every((r) => (r.identical ?? r.identical_v0) === 'yes')

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center gap-2">
        <span className="label mr-1">Agents</span>
        {sizes.map((s) => <button key={s} onClick={() => setN(s)} className={`num rounded-full border px-3 py-1.5 text-xs ${n === s ? 'border-accent bg-accent/10 text-accent' : 'border-line text-mute hover:text-ink'}`}>{compact(s)}</button>)}
        <span className="label ml-4 mr-1">V6 workload</span>
        {['default', 'low', 'high'].map((s) => <button key={s} onClick={() => setScn(s)} className={`rounded-full border px-3 py-1.5 text-xs ${scn === s ? 'border-accent bg-accent/10 text-accent' : 'border-line text-mute hover:text-ink'}`}>{s}</button>)}
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="V5 vs V0 (V5 run)" value={x(v5r?.kernel_speedup_v0)} sub={`${secs(v5r?.kernel_median_s)} vs ${secs(v0_5?.kernel_median_s)} kernel`} color="#4ad6a0" />
        <Stat label="V6 base vs V0" value={x(base?.kernel_speedup_v0)} sub={`${secs(base?.kernel_median_s)} kernel (V6 run)`} color="#5eead4" />
        <Stat label="Best V6 vs V0" value={x(best?.kernel_speedup_v0)} sub={best ? `${best.backend} · ${secs(best.kernel_median_s)}` : ''} color="#4da3ff" />
        <Stat label="Best V6 vs V5" value={x(best?.kernel_speedup_v5)} sub={v6v5 ? `V5 ${secs(v6v5.kernel_median_s)} in same run` : ''} color="#f5b83d" />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title={`Backend comparison — ${compact(n)} agents`} sub="V5 benchmark run · median kernel time, log scale">
          <div className="h-[280px]"><ResponsiveContainer>
            <BarChart data={v5n} margin={{ left: 0, right: 10 }}>
              <CartesianGrid {...grid} /><XAxis dataKey="backend" {...axis} /><YAxis {...axis} scale="log" domain={[(m: number) => m / 2, (m: number) => m * 1.5]} allowDataOverflow tickFormatter={(v) => secs(v)} width={64} />
              <Tooltip {...tooltipStyle} formatter={(v: any, _n, p) => [`${secs(v)} · ${x(p.payload.kernel_speedup_v0)} vs V0`, 'kernel median']} />
              <Bar dataKey="kernel_median_s" radius={[4, 4, 0, 0]} isAnimationActive={false}>{v5n.map((r) => <Cell key={r.backend} fill={BCOL[r.backend]} />)}</Bar>
            </BarChart></ResponsiveContainer></div>
          <div className="mt-2 flex flex-wrap gap-1.5">{v5n.map((r) => <Badge key={r.backend} color={BCOL[r.backend]}>{r.backend} {x(r.kernel_speedup_v0)}</Badge>)}</div>
        </Card>

        <Card title="Scaling with population size" sub="V5 benchmark run · kernel median, log–log">
          <div className="h-[280px]"><ResponsiveContainer>
            <LineChart data={scaling} margin={{ left: 0, right: 14 }}>
              <CartesianGrid {...grid} /><XAxis dataKey="agents" {...axis} scale="log" type="number" domain={['dataMin', 'dataMax']} ticks={sizes} tickFormatter={compact} />
              <YAxis {...axis} scale="log" domain={['auto', 'auto']} tickFormatter={(v) => secs(v)} width={64} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => secs(v)} labelFormatter={(a) => `${nf(a as number)} agents`} /><Legend wrapperStyle={{ fontSize: 12 }} />
              {Object.keys(BCOL).map((b) => <Line key={b} dataKey={b} stroke={BCOL[b]} strokeWidth={b === 'V5' ? 3 : 1.8} dot={{ r: 3 }} isAnimationActive={false} />)}
            </LineChart></ResponsiveContainer></div>
        </Card>
      </div>

      <Card title={`V6 optimisation variants — ${compact(n)} agents, "${scn}" workload`} sub="Kernel speedup vs V0 CPU (same V6 run). Variant keys: E1 aggregation · E2 async/graph · E3 micro-opts · E4 block size"
        right={<Badge color="#4ad6a0">{variants.every((v) => v.identical_v0 === 'yes') ? 'all outputs identical to V0' : 'check identity column'}</Badge>}>
        <div className="h-[620px]"><ResponsiveContainer>
          <BarChart data={variants} layout="vertical" margin={{ left: 20, right: 30 }}>
            <CartesianGrid {...grid} horizontal={false} /><XAxis type="number" {...axis} unit="×" />
            <YAxis type="category" dataKey="backend" {...axis} width={170} fontSize={10} interval={0} />
            <Tooltip {...tooltipStyle} formatter={(v: any, _n, p) => [`${x(v)} vs V0 · ${x(p.payload.kernel_speedup_v5)} vs V5 · ${secs(p.payload.kernel_median_s)}`, p.payload.opts]} />
            <Bar dataKey="kernel_speedup_v0" radius={[0, 4, 4, 0]} isAnimationActive={false}>
              {variants.map((r) => <Cell key={r.backend} fill={r.backend === best?.backend ? '#5eead4' : r.kernel_speedup_v5 != null && r.kernel_speedup_v5 < 1 ? '#ff5d6c' : '#4da3ff'} />)}
            </Bar>
          </BarChart></ResponsiveContainer></div>
        <p className="mt-2 text-xs text-mute">Teal = fastest · red = slower than V5 at this size (e.g. large block sizes at small N).</p>
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Kernel profile (V6)" sub="Per-day location-update vs step time, ms (median)">
          <div className="h-[480px]"><ResponsiveContainer>
            <BarChart data={prof} layout="vertical" margin={{ left: 20 }}>
              <CartesianGrid {...grid} horizontal={false} /><XAxis type="number" {...axis} /><YAxis type="category" dataKey="backend" {...axis} width={150} fontSize={10} interval={0} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => `${nf(v, 3)} ms`} /><Legend wrapperStyle={{ fontSize: 12 }} />
              <Bar dataKey="loc_ms_median" name="location update" stackId="a" fill="#a78bfa" isAnimationActive={false} />
              <Bar dataKey="step_ms_median" name="step" stackId="a" fill="#4da3ff" isAnimationActive={false} />
            </BarChart></ResponsiveContainer></div>
        </Card>

        <Card title="Transfer & timing detail" sub={`${compact(n)} agents · V6 run`}>
          <div className="max-h-[300px] overflow-auto"><table className="w-full text-xs">
            <thead className="sticky top-0 bg-panel"><tr className="label text-left"><th className="pb-2">Backend</th><th className="pb-2 text-right">Kernel</th><th className="pb-2 text-right">CV</th><th className="pb-2 text-right">E2E</th><th className="pb-2 text-right">H2D</th><th className="pb-2 text-right">D2H</th><th className="pb-2 text-right">×V0</th></tr></thead>
            <tbody>{v6rows.map((r: BenchRow) => (
              <tr key={r.backend} className="border-t border-line"><td className="py-1.5">{r.backend}</td><td className="num text-right">{secs(r.kernel_median_s)}</td><td className="num text-right">{nf(r.kernel_cv_pct, 1)}%</td><td className="num text-right">{r.e2e_median_s ? secs(r.e2e_median_s) : '—'}</td><td className="num text-right">{r.h2d_median_s ? secs(r.h2d_median_s) : '—'}</td><td className="num text-right">{r.d2h_median_s ? secs(r.d2h_median_s) : '—'}</td><td className="num text-right">{x(r.kernel_speedup_v0)}</td></tr>))}</tbody>
          </table></div>
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Benchmark environment">
          <dl className="grid grid-cols-[auto,1fr] gap-x-4 gap-y-1.5 text-xs">
            {[['GPU', m6.gpu_model], ['CPU', m6.cpu_model], ['CPU cores (logical)', m6.cpu_logical_cores], ['CUDA compiler', m6.cuda_compiler], ['CUDA driver / runtime', `${m6.cuda_driver} / ${m6.cuda_runtime}`], ['Repetitions', m6.repetitions], ['V6 git commit', d.git_commit?.slice(0, 7)], ['OS', m6.os]].map(([k, v]) => (<><dt className="text-mute">{k}</dt><dd className="text-right">{v}</dd></>))}
          </dl>
        </Card>
        <Card title="Interpretation notes">
          <ul className="list-disc space-y-1.5 pl-4 text-xs text-mute">
            <li>V5 and V6 comparisons come from <b className="text-ink">two separate Kaggle runs</b>; V0 timing differs between them (e.g. {secs(v0_5?.kernel_median_s)} vs {secs(v6rows.find((r) => r.backend === 'V0')?.kernel_median_s)} at this size). Compare speedups within a file, not across files.</li>
            <li>Kernel time includes the per-day count readback (or one deferred copy for async/graph variants); E2E also includes transfers and graph build.</li>
            <li>{allIdentical ? 'Every recorded backend row reports output identical to V0 / V5.' : 'Some rows do not report identical output — see tables.'}</li>
            <li>Benchmarks were run on a single Tesla T4 (Kaggle); no other GPU data is recorded. Agent counts (10k–5M) and the default/low/high workload labels are the benchmark's own configurations.</li>
          </ul>
          {m6.notes && <p className="mt-3 text-[11px] text-mute">{m6.notes}</p>}
        </Card>
      </div>
    </div>
  )
}
