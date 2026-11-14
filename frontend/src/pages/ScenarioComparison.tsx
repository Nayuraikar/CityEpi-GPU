import { useMemo, useState } from 'react'
import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Scatter, ScatterChart, Tooltip, XAxis, YAxis, ZAxis } from 'recharts'
import { useApi } from '../api/client'
import type { Run, Runs, Seeds } from '../api/types'
import { Card, Experimental, Loaded, Notice, PageHeader, axis, grid, tooltipStyle } from '../components/ui'
import { SCENARIO_COLORS, nf, pct } from '../lib/format'

export default function ScenarioComparison() {
  const runs = useApi<Runs>('/api/epidemic')
  const seeds = useApi<Seeds>('/api/epidemic/seeds')
  return (
    <>
      <PageHeader title="Scenario Comparison" subtitle="Legacy vs household populations, and low / baseline / high transmission — recorded runs and 10-seed validation." />
      <Loaded state={runs}>{(r) => <Loaded state={seeds}>{(s) => <Body runs={r} seeds={s} />}</Loaded>}</Loaded>
    </>
  )
}

type Metric = 'I' | 'incidence' | 'R'
const METRICS: { id: Metric; label: string }[] = [{ id: 'I', label: 'Infectious' }, { id: 'incidence', label: 'Daily incidence' }, { id: 'R', label: 'Recovered' }]

function overlay(keys: string[], runs: Runs, m: Metric) {
  return runs[keys[0]].curve.map((_, i) => Object.fromEntries([['day', i], ...keys.map((k) => [k, runs[k].curve[i][m]])]))
}

function SummaryTable({ list }: { list: Run[] }) {
  return (
    <div className="overflow-x-auto"><table className="w-full text-sm">
      <thead><tr className="label text-left"><th className="pb-2">Run</th><th className="px-2 pb-2 text-right">Attack</th><th className="px-2 pb-2 text-right">Peak&nbsp;I</th><th className="px-2 pb-2 text-right">Day</th><th className="px-2 pb-2 text-right">Incid.</th><th className="pb-2 text-right">Final&nbsp;S</th></tr></thead>
      <tbody>{list.map((r) => (
        <tr key={r.key} className="border-t border-line"><td className="py-2"><span className="mr-2 inline-block h-2 w-2 rounded-full" style={{ background: SCENARIO_COLORS[r.key] }} /><span className="capitalize">{r.key}</span></td>
          <td className="num px-2 text-right">{pct(r.summary.attack_rate_pct, 2)}</td><td className="num px-2 text-right">{nf(r.summary.peak_infectious)}</td><td className="num px-2 text-right">{r.summary.peak_day}</td><td className="num px-2 text-right">{nf(r.summary.peak_daily_incidence)}</td><td className="num text-right">{nf(r.summary.final.S)}</td></tr>))}</tbody>
    </table></div>
  )
}

function Overlay({ keys, runs, metric }: { keys: string[]; runs: Runs; metric: Metric }) {
  const data = useMemo(() => overlay(keys, runs, metric), [keys, runs, metric])
  return (
    <div className="h-[300px]"><ResponsiveContainer>
      <LineChart data={data} margin={{ left: 0, right: 12, top: 8 }}>
        <CartesianGrid {...grid} /><XAxis dataKey="day" {...axis} /><YAxis {...axis} tickFormatter={(v) => Intl.NumberFormat('en', { notation: 'compact' }).format(v)} />
        <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [nf(v), runs[n]?.label ?? n]} labelFormatter={(d) => `Day ${d}`} /><Legend formatter={(v) => runs[v]?.label ?? v} wrapperStyle={{ fontSize: 12 }} />
        {keys.map((k) => <Line key={k} dataKey={k} stroke={SCENARIO_COLORS[k]} strokeWidth={2} dot={false} isAnimationActive={false} />)}
      </LineChart>
    </ResponsiveContainer></div>
  )
}

function Body({ runs, seeds }: { runs: Runs; seeds: Seeds }) {
  const [metric, setMetric] = useState<Metric>('I')
  const [showSeeds, setShowSeeds] = useState(true)
  const pop = ['legacy', 'household'], beta = ['low', 'baseline', 'high']
  const sd = (s: string) => seeds.summary.find((x) => x.scenario === s)!

  // Seed spaghetti for infectious curves
  const seedData = useMemo(() => Array.from({ length: 101 }, (_, d) => {
    const row: Record<string, number> = { day: d }
    for (const sc of beta) for (const [seed, c] of Object.entries(seeds.curves[sc] ?? {})) row[`${sc}-${seed}`] = c[d]?.I
    return row
  }), [seeds])
  const seedKeys = Object.keys(seedData[0]).filter((k) => k !== 'day')

  const strip = seeds.per_seed.map((r) => ({ ...r, y: beta.indexOf(r.scenario) }))

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        {METRICS.map((m) => (
          <button key={m.id} onClick={() => setMetric(m.id)} className={`rounded-full border px-3 py-1.5 text-xs ${metric === m.id ? 'border-accent bg-accent/10 text-accent' : 'border-line text-mute hover:text-ink'}`}>{m.label}</button>
        ))}
        <span className="ml-auto"><Experimental /></span>
      </div>

      <div>
        <h2 className="mb-3 text-base font-semibold">Population structure: legacy vs household</h2>
        <div className="grid gap-5 lg:grid-cols-3">
          <Card title="Trajectories" sub="Same transmission settings, seed 42" className="lg:col-span-2"><Overlay keys={pop} runs={runs} metric={metric} /></Card>
          <Card title="Summary" sub="Seed 42, 100 days · Incid. = peak daily incidence"><SummaryTable list={pop.map((k) => runs[k])} />
            <p className="mt-3 text-xs text-mute">The legacy population (no explicit households) reached {pct(runs.legacy.summary.attack_rate_pct, 2)} attack rate; the household population reached {pct(runs.household.summary.attack_rate_pct, 2)}. Both are single-seed results with experimental transmission settings.</p></Card>
        </div>
      </div>

      <div>
        <h2 className="mb-3 text-base font-semibold">Transmission sensitivity: low / baseline / high</h2>
        <Notice tone="info">Numeric β values for these scenarios are not recorded in the bundle (only the labels low / baseline / high), so none are shown. Household population, seed 42.</Notice>
        <div className="mt-3 grid gap-5 lg:grid-cols-3">
          <Card title="Trajectories" className="lg:col-span-2"><Overlay keys={beta} runs={runs} metric={metric} /></Card>
          <Card title="Summary" sub="Seed 42"><SummaryTable list={beta.map((k) => runs[k])} /></Card>
        </div>
      </div>

      <div>
        <h2 className="mb-3 text-base font-semibold">10-seed validation <span className="text-sm font-normal text-mute">(seeds {seeds.seed_range[0]}–{seeds.seed_range[1]}, V0 CPU reference)</span></h2>
        <div className="grid gap-5 lg:grid-cols-3">
          <Card title="Attack rate per seed" sub="Each dot = one seed (mean ± SD in the table)" className="lg:col-span-1">
            <div className="h-[260px]"><ResponsiveContainer>
              <ScatterChart margin={{ left: 0, right: 20, top: 10 }}>
                <CartesianGrid {...grid} />
                <XAxis type="number" dataKey="attack_rate_pct" {...axis} unit="%" domain={[0, 80]} name="attack" />
                <YAxis type="number" dataKey="y" {...axis} domain={[-0.5, 2.5]} ticks={[0, 1, 2]} tickFormatter={(v) => beta[v]} width={60} />
                <ZAxis range={[60, 60]} />
                <Tooltip {...tooltipStyle} cursor={false} formatter={(v: any, n: any) => n === 'attack' ? [`${v}%`, 'Attack rate'] : [v, n]} />
                {beta.map((sc) => <Scatter key={sc} data={strip.filter((s) => s.scenario === sc)} fill={SCENARIO_COLORS[sc]} isAnimationActive={false} />)}
              </ScatterChart></ResponsiveContainer></div>
          </Card>
          <Card title="Statistics" className="lg:col-span-2">
            <div className="overflow-x-auto"><table className="w-full text-sm">
              <thead><tr className="label text-left"><th className="pb-2">Scenario</th><th className="pb-2 text-right">Attack mean ± SD</th><th className="pb-2 text-right">Range</th><th className="pb-2 text-right">Peak I mean ± SD</th><th className="pb-2 text-right">Peak day (mean)</th><th className="pb-2 text-right">Mean peak incid.</th></tr></thead>
              <tbody>{beta.map((s) => { const x = sd(s); return (
                <tr key={s} className="border-t border-line"><td className="py-2"><span className="mr-2 inline-block h-2 w-2 rounded-full" style={{ background: SCENARIO_COLORS[s] }} />{s}</td>
                  <td className="num text-right">{nf(x.attack_mean, 2)} ± {nf(x.attack_sd, 2)}%</td><td className="num text-right">{nf(x.attack_min, 1)}–{nf(x.attack_max, 1)}%</td>
                  <td className="num text-right">{nf(x.peak_mean, 0)} ± {nf(x.peak_sd, 0)}</td><td className="num text-right">{nf(x.peak_day_mean, 1)}</td><td className="num text-right">{nf(x.incidence_mean, 0)}</td></tr>)})}</tbody>
            </table></div>
            <p className="mt-3 text-xs text-mute">Statistics are read from summary_statistics.csv as recorded. “Mean peak incid.” is the file's incidence_mean column. V6 was not run for these seeds (V0 only).</p>
          </Card>
        </div>
        <Card className="mt-5" title="Infectious curves across seeds" sub={`${seedKeys.length} per-seed V0 curves, coloured by scenario`}
          right={<button onClick={() => setShowSeeds(!showSeeds)} className="rounded-md border border-line px-2 py-0.5 text-xs text-mute hover:text-ink">{showSeeds ? 'hide' : 'show'}</button>}>
          {showSeeds && <div className="h-[300px]"><ResponsiveContainer>
            <LineChart data={seedData} margin={{ left: 0, right: 12, top: 8 }}>
              <CartesianGrid {...grid} /><XAxis dataKey="day" {...axis} /><YAxis {...axis} tickFormatter={(v) => Intl.NumberFormat('en', { notation: 'compact' }).format(v)} />
              <Tooltip content={() => null} />
              {seedKeys.map((k) => <Line key={k} dataKey={k} stroke={SCENARIO_COLORS[k.split('-')[0]]} strokeOpacity={0.55} strokeWidth={1.2} dot={false} isAnimationActive={false} />)}
            </LineChart></ResponsiveContainer></div>}
        </Card>
      </div>
    </div>
  )
}
