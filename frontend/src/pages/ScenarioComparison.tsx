import { useMemo, useState } from 'react'
import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Scatter, ScatterChart, Tooltip, XAxis, YAxis, ZAxis } from 'recharts'
import { useApi } from '../api/client'
import type { Run, Runs, Seeds } from '../api/types'
import { Badge, Card, Dot, EmptyState, Experimental, Loaded, Notice, PageHeader, Segmented, SectionTitle, Source, axis, axisLabel, grid, legendStyle, tooltipStyle } from '../components/ui'
import { SCENARIO_COLORS, compact, nf, pct } from '../lib/format'
import { C } from '../lib/theme'

export default function ScenarioComparison() {
  const runs = useApi<Runs>('/api/epidemic')
  const seeds = useApi<Seeds>('/api/epidemic/seeds')
  return (
    <>
      <PageHeader subtitle="Legacy vs household populations, low / baseline / high transmission, and the ten-seed validation. Seed-42 comparisons are single recorded runs; the ten-seed statistics are V0 CPU-only." />
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
    <div className="overflow-x-auto"><table className="tbl">
      <thead><tr className="text-left"><th>Run</th><th className="px-2 text-right">Attack</th><th className="px-2 text-right">Peak&nbsp;I</th><th className="px-2 text-right">Day</th><th className="px-2 text-right">Incid.</th><th className="text-right">Final&nbsp;S</th></tr></thead>
      <tbody>{list.map((r) => (
        <tr key={r.key}><td><Dot color={SCENARIO_COLORS[r.key]} /><span className="capitalize">{r.key}</span></td>
          <td className="num px-2 text-right">{pct(r.summary.attack_rate_pct, 2)}</td><td className="num px-2 text-right">{nf(r.summary.peak_infectious)}</td><td className="num px-2 text-right">{r.summary.peak_day}</td><td className="num px-2 text-right">{nf(r.summary.peak_daily_incidence)}</td><td className="num text-right">{nf(r.summary.final.S)}</td></tr>))}</tbody>
    </table></div>
  )
}

function Overlay({ keys, runs, metric }: { keys: string[]; runs: Runs; metric: Metric }) {
  const data = useMemo(() => overlay(keys, runs, metric), [keys, runs, metric])
  return (
    <div className="h-[300px]"><ResponsiveContainer>
      <LineChart data={data} margin={{ left: 0, right: 12, top: 8, bottom: 14 }}>
        <CartesianGrid {...grid} /><XAxis dataKey="day" {...axis} interval={9} label={axisLabel('day')} /><YAxis {...axis} width={48} tickFormatter={(v) => compact(v)} />
        <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [nf(v), runs[n]?.label ?? n]} labelFormatter={(d) => `Day ${d}`} /><Legend formatter={(v) => runs[v]?.label ?? v} wrapperStyle={legendStyle} />
        {keys.map((k) => <Line key={k} dataKey={k} stroke={SCENARIO_COLORS[k]} strokeWidth={2.2} dot={false} isAnimationActive={false} />)}
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
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Segmented label="Metric" value={metric} onChange={setMetric} options={METRICS} />
        <span className="flex gap-1.5"><Source kind="recorded" /><Experimental /></span>
      </div>

      <section>
        <SectionTitle title="Population structure: legacy vs household" />
        <div className="mb-3"><Notice>The legacy and household populations also differ in their home <i>and</i> destination assignments (different CEPOP inputs), so this is <b>not a pure causal experiment isolating the effect of households</b>. Transmission parameters are not recorded with these runs.</Notice></div>
        <div className="grid gap-5 lg:grid-cols-5">
          <Card title="Trajectories" sub="Seed 42 · 100 days · 100 initially infectious" className="lg:col-span-3"><Overlay keys={pop} runs={runs} metric={metric} /></Card>
          <Card className="lg:col-span-2" title="Summary" sub="Seed 42, 100 days · Incid. = peak daily incidence"><SummaryTable list={pop.map((k) => runs[k])} />
            <p className="mt-3 text-xs text-mute">The legacy population (no explicit households) reached {pct(runs.legacy.summary.attack_rate_pct, 2)} attack rate; the household population reached {pct(runs.household.summary.attack_rate_pct, 2)}. Both are single-seed results with experimental transmission settings.</p></Card>
        </div>
      </section>

      <section>
        <SectionTitle title="Transmission sensitivity: low / baseline / high" />
        <Notice tone="info">Numeric β values for these scenarios are not recorded in the bundle (only the labels low / baseline / high), so none are shown. Household population, seed 42.</Notice>
        <div className="mt-3 grid gap-5 lg:grid-cols-5">
          <Card title="Trajectories" className="lg:col-span-3"><Overlay keys={beta} runs={runs} metric={metric} /></Card>
          <Card className="lg:col-span-2" title="Summary" sub="Seed 42"><SummaryTable list={beta.map((k) => runs[k])} /></Card>
        </div>
      </section>

      <section>
        <SectionTitle title="Ten-seed validation" sub={`simulation seeds ${seeds.seed_range[0]}–${seeds.seed_range[1]} · household population only · low / baseline / high`} right={<span className="flex gap-1.5"><Badge color={C.slate}>V0 CPU only</Badge><Source kind="recorded" /></span>} />
        <div className="mb-3"><Notice tone="info">
          <b>V0 CPU-only.</b> All {seeds.n_seeds * 3} runs used the {seeds.backend}; no V6/GPU run exists for these seeds ({Object.values(seeds.v6_runs_present).reduce((a, b) => a + b, 0)} recorded). Dataset: <span className="num">{seeds.population_inputs.join(', ')}</span>.
          The seeds change only the simulation&apos;s random draws on <b>one fixed synthetic population</b>. The spread below is run-to-run randomness of this model, <b>not uncertainty about the actual city of Bengaluru</b>, and it says nothing about the legacy population (no ten-seed legacy run is recorded).
        </Notice></div>
        <div className="grid gap-5 lg:grid-cols-3">
          <Card title="Attack rate per seed" sub="Each dot = one seed (mean ± SD in the table)" className="lg:col-span-1">
            <div className="h-[260px]"><ResponsiveContainer>
              <ScatterChart margin={{ left: 0, right: 20, top: 10 }}>
                <CartesianGrid {...grid} />
                <XAxis type="number" dataKey="attack_rate_pct" {...axis} unit="%" domain={[0, 80]} name="attack" />
                {/* seed is carried on each datum so the tooltip can name it */}
                <YAxis type="number" dataKey="y" {...axis} domain={[-0.5, 2.5]} ticks={[0, 1, 2]} tickFormatter={(v) => beta[v]} width={60} />
                <ZAxis type="number" dataKey="seed" range={[70, 70]} name="seed" />
                <Tooltip {...tooltipStyle} cursor={false} formatter={(v: any, n: any) => n === 'attack' ? [`${v}%`, 'Attack rate'] : n === 'seed' ? [v, 'Seed'] : [v, n]} />
                {beta.map((sc) => <Scatter key={sc} data={strip.filter((s) => s.scenario === sc)} fill={SCENARIO_COLORS[sc]} isAnimationActive={false} />)}
              </ScatterChart></ResponsiveContainer></div>
          </Card>
          <Card title="Statistics (10 seeds, V0 CPU)" className="lg:col-span-2" right={<Badge color={C.slate}>V0 CPU only</Badge>}>
            <div className="overflow-x-auto"><table className="tbl">
              <thead><tr className="text-left"><th>Scenario</th><th className="px-2 text-right">Attack rate % mean</th><th className="px-2 text-right">SD</th><th className="px-2 text-right">Min</th><th className="px-2 text-right">Max</th><th className="px-2 text-right">Peak I mean</th><th className="px-2 text-right">SD</th><th className="px-2 text-right">Min*</th><th className="px-2 text-right">Max*</th><th className="px-2 text-right">Peak day mean</th><th className="text-right">Peak incid. mean</th></tr></thead>
              <tbody>{beta.map((s) => { const x = sd(s), pr = seeds.peak_range[s]; return (
                <tr key={s}><td><Dot color={SCENARIO_COLORS[s]} /><span className="capitalize">{s}</span></td>
                  <td className="num px-2 text-right">{nf(x.attack_mean, 2)}</td><td className="num px-2 text-right">{nf(x.attack_sd, 2)}</td><td className="num px-2 text-right">{nf(x.attack_min, 2)}</td><td className="num px-2 text-right">{nf(x.attack_max, 2)}</td>
                  <td className="num px-2 text-right">{nf(x.peak_mean, 1)}</td><td className="num px-2 text-right">{nf(x.peak_sd, 1)}</td><td className="num px-2 text-right">{nf(pr?.peak_min)}</td><td className="num px-2 text-right">{nf(pr?.peak_max)}</td>
                  <td className="num px-2 text-right">{nf(x.peak_day_mean, 1)}</td><td className="num text-right">{nf(x.incidence_mean, 1)}</td></tr>)})}</tbody>
            </table></div>
            <p className="mt-3 text-xs text-mute">Mean, SD and attack-rate min/max are read from summary_statistics.csv as recorded ({seeds.sd_convention}). *Peak-infectious min/max are not in that file; they are taken directly from the per-seed rows of all_seed_results.csv. “Peak incid. mean” is the file&apos;s <code>incidence_mean</code> column (mean of each seed&apos;s peak daily incidence). The recorded statistics file does not include a peak-day min/max.</p>
          </Card>
        </div>
        <Card className="mt-5" title="Infectious curves across seeds" sub={`${seedKeys.length} per-seed V0 curves, coloured by scenario`}
          right={<button onClick={() => setShowSeeds(!showSeeds)} className="btn" aria-expanded={showSeeds}>{showSeeds ? 'Hide' : 'Show'}</button>}>
          {showSeeds && (seedKeys.length === 0 ? <EmptyState title="No per-seed curves recorded">The bundle holds no per-seed infectious curves for these scenarios.</EmptyState> : <><div className="h-[300px]"><ResponsiveContainer>
            <LineChart data={seedData} margin={{ left: 0, right: 12, top: 8, bottom: 14 }}>
              <CartesianGrid {...grid} /><XAxis dataKey="day" {...axis} interval={9} label={axisLabel('day')} /><YAxis {...axis} width={48} tickFormatter={(v) => compact(v)} />
              <Tooltip content={() => null} />
              {seedKeys.map((k) => <Line key={k} dataKey={k} stroke={SCENARIO_COLORS[k.split('-')[0]]} strokeOpacity={0.55} strokeWidth={1.2} dot={false} isAnimationActive={false} />)}
            </LineChart></ResponsiveContainer></div>
          <div className="mt-2 flex flex-wrap gap-3 text-xs text-mute">{beta.map((b) => <span key={b}><Dot color={SCENARIO_COLORS[b]} /><span className="capitalize">{b}</span></span>)}</div></>)}
        </Card>
      </section>
    </div>
  )
}
