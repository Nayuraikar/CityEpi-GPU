import { useState } from 'react'
import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Line, LineChart, ReferenceLine, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useApi } from '../api/client'
import type { Runs } from '../api/types'
import { Card, Dot, Experimental, Loaded, Notice, PageHeader, Segmented, Source, Stat, ToggleChip, axis, axisLabel, grid, tooltipStyle } from '../components/ui'
import { SCENARIO_COLORS, compact, nf, pct } from '../lib/format'
import { C, SEIR as COMP, SEIR_NAMES as NAMES } from '../lib/theme'

const POP = ['legacy', 'household'], BETA = ['low', 'baseline', 'high']

export default function EpidemicAnalysis() {
  const s = useApi<Runs>('/api/epidemic')
  return (
    <>
      <PageHeader subtitle="Recorded S/E/I/R trajectories for the seed-42, 100-day runs: population comparison (legacy vs household) and transmission sensitivity (low / baseline / high). Curves come from the recorded V6 CUDA output, whose daily checksum equals the V0 CPU reference." />
      <Loaded state={s}>{(runs) => <Body runs={runs} />}</Loaded>
    </>
  )
}

function Body({ runs }: { runs: Runs }) {
  const [key, setKey] = useState('baseline')
  const [vis, setVis] = useState({ S: true, E: true, I: true, R: true })
  const [mode, setMode] = useState<'count' | 'share'>('count')
  const r = runs[key], sm = r.summary
  const same = runs.household && runs.baseline && runs.household.daily_checksum === runs.baseline.daily_checksum && runs.household.dataset_id === runs.baseline.dataset_id
  const data = r.curve.map((p) => mode === 'share' ? { ...p, S: p.S / r.agents * 100, E: p.E / r.agents * 100, I: p.I / r.agents * 100, R: p.R / r.agents * 100 } : p)
  const attack = Object.values(runs).map((x) => ({ key: x.key, label: x.label, attack: x.summary.attack_rate_pct }))

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-x-6 gap-y-3">
        <div className="flex flex-wrap items-center gap-x-6 gap-y-3">
          <Segmented label="Population" value={key} onChange={setKey} options={POP.filter((k) => runs[k]).map((k) => ({ id: k, label: runs[k].label, color: SCENARIO_COLORS[k] }))} />
          <Segmented label="Transmission" value={key} onChange={setKey} options={BETA.filter((k) => runs[k]).map((k) => ({ id: k, label: runs[k].label, color: SCENARIO_COLORS[k] }))} />
        </div>
        <span className="flex gap-1.5"><Source kind="recorded" /><Experimental>Experimental transmission</Experimental></span>
      </div>
      {same && key === 'household' && <Notice tone="info">The household-population run and the baseline-transmission run use the same input file and have the same daily checksum <span className="num">{r.daily_checksum}</span>; they are one recorded configuration shown under two names.</Notice>}
      {same && key === 'baseline' && <Notice tone="info">The baseline-transmission run is the household-population run (same input file, same daily checksum <span className="num">{r.daily_checksum}</span>).</Notice>}

      <div key={key} className="grid animate-fade-up grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="Attack rate" value={pct(sm.attack_rate_pct, 2)} sub="1 − S_final/N" color={C.coral} hint="Cumulative share of agents ever exposed (E+I+R) by day 100, computed as 1 − S(day 100)/N." />
        <Stat label="Peak infectious" value={nf(sm.peak_infectious)} sub={`day ${sm.peak_day}`} color={C.coral} />
        <Stat label="Peak daily incidence" value={nf(sm.peak_daily_incidence)} sub={`day ${sm.peak_incidence_day} · new exposures`} color={C.amber} />
        <Stat label="Final R" value={nf(sm.final.R)} sub={`${pct(sm.recovered_pct, 2)} of agents`} color={C.sage} />
      </div>

      <Card title="S / E / I / R trajectories" sub={`${r.label} · ${nf(r.agents)} agents · seed ${r.seed} · ${r.initial_infected} initial infectious`}
        right={
          <div className="flex flex-wrap items-center justify-end gap-1.5">
            {(Object.keys(COMP) as (keyof typeof COMP)[]).map((c) => (
              <ToggleChip key={c} on={vis[c]} color={COMP[c]} onClick={() => setVis({ ...vis, [c]: !vis[c] })}>{c}</ToggleChip>
            ))}
            <span className="mx-1 h-5 w-px bg-line" />
            <Segmented value={mode} onChange={setMode} options={[{ id: 'count', label: 'Counts' }, { id: 'share', label: '% of pop.' }]} />
          </div>}>
        <div className="h-[340px]">
          <ResponsiveContainer>
            <LineChart data={data} margin={{ left: 0, right: 12, top: 22, bottom: 14 }}>
              <CartesianGrid {...grid} />
              <XAxis dataKey="day" {...axis} interval={9} label={axisLabel('day')} />
              <YAxis {...axis} width={48} tickFormatter={(v) => mode === 'share' ? `${v}%` : compact(v)} />
              <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [mode === 'share' ? `${nf(v, 2)}%` : nf(v), NAMES[n as keyof typeof NAMES]]} labelFormatter={(d) => `Day ${d}`} />
              {(Object.keys(COMP) as (keyof typeof COMP)[]).map((c) => vis[c] && <Line key={c} dataKey={c} stroke={COMP[c]} dot={false} strokeWidth={2.2} isAnimationActive={false} />)}
              <ReferenceLine x={sm.peak_day} stroke={C.coral} strokeDasharray="4 4" label={{ value: 'peak I', fill: C.coral, fontSize: 10, position: 'top' }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Exposed & infectious (zoomed)" sub="E and I on their own scale — the S curve dominates the chart above">
          <div className="h-[250px]">
            <ResponsiveContainer>
              <LineChart data={r.curve} margin={{ left: 0, right: 12, top: 8 }}>
                <CartesianGrid {...grid} />
                <XAxis dataKey="day" {...axis} interval={9} /><YAxis {...axis} width={48} tickFormatter={compact} />
                <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [nf(v), NAMES[n as keyof typeof NAMES]]} labelFormatter={(d) => `Day ${d}`} />
                <Line dataKey="E" stroke={COMP.E} dot={false} strokeWidth={2.2} isAnimationActive={false} />
                <Line dataKey="I" stroke={COMP.I} dot={false} strokeWidth={2.2} isAnimationActive={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Daily incidence" sub="New exposures per day = S(t−1) − S(t), derived from recorded S">
          <div className="h-[250px]">
            <ResponsiveContainer>
              <AreaChart data={r.curve.slice(1)} margin={{ left: 0, right: 12, top: 8 }}>
                <defs><linearGradient id="inc" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor={C.amber} stopOpacity={0.4} /><stop offset="100%" stopColor={C.amber} stopOpacity={0.02} /></linearGradient></defs>
                <CartesianGrid {...grid} />
                <XAxis dataKey="day" {...axis} /><YAxis {...axis} width={48} tickFormatter={compact} />
                <Tooltip {...tooltipStyle} formatter={(v: any) => [nf(v), 'New exposures']} labelFormatter={(d) => `Day ${d}`} />
                <Area dataKey="incidence" stroke={C.amber} strokeWidth={2.2} fill="url(#inc)" isAnimationActive={false} />
                <ReferenceLine x={sm.peak_incidence_day} stroke={C.amber} strokeDasharray="4 4" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <Card title="Attack rate by run" sub="Cumulative, day 100 · selected run highlighted · click a bar to switch">
        <div className="h-[220px]">
          <ResponsiveContainer>
            <BarChart data={attack} layout="vertical" margin={{ left: 4, right: 24 }}>
              <CartesianGrid {...grid} horizontal={false} />
              <XAxis type="number" {...axis} unit="%" domain={[0, 100]} />
              <YAxis type="category" dataKey="key" {...axis} width={80} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => [`${nf(v, 2)}%`, 'Attack rate']} />
              <Bar dataKey="attack" radius={[0, 5, 5, 0]} isAnimationActive={false} barSize={18} cursor="pointer" onClick={(d: any) => d?.key && setKey(d.key)}>
                {attack.map((a) => <Cell key={a.key} fill={SCENARIO_COLORS[a.key]} fillOpacity={a.key === key ? 1 : 0.4} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <Card title="All recorded runs" sub="Final compartments on day 100 (counts of agents) and derived indicators · seed 42" right={<Source kind="recorded" />}>
        <div className="overflow-x-auto"><table className="tbl">
          <thead><tr className="text-left"><th>Run</th><th className="px-2 text-right">Attack</th><th className="px-2 text-right">Peak I</th><th className="px-2 text-right">Peak day</th><th className="px-2 text-right">Peak incid. (day)</th><th className="px-2 text-right">S</th><th className="px-2 text-right">E</th><th className="px-2 text-right">I</th><th className="text-right">R</th></tr></thead>
          <tbody>{Object.values(runs).map((x) => (
            <tr key={x.key} className={x.key === key ? 'bg-surface-2' : ''}><td><Dot color={SCENARIO_COLORS[x.key]} />{x.label}</td>
              <td className="num px-2 text-right">{pct(x.summary.attack_rate_pct, 2)}</td><td className="num px-2 text-right">{nf(x.summary.peak_infectious)}</td><td className="num px-2 text-right">{x.summary.peak_day}</td>
              <td className="num px-2 text-right">{nf(x.summary.peak_daily_incidence)} ({x.summary.peak_incidence_day})</td>
              {(['S', 'E', 'I', 'R'] as const).map((c) => <td key={c} className={`num text-right ${c === 'R' ? '' : 'px-2'}`}>{nf(x.summary.final[c])}</td>)}</tr>))}</tbody>
        </table></div>
        <p className="mt-3 text-xs text-mute">Numeric transmission parameters (β) are not recorded with these results, so low / baseline / high are shown as labels only. Attack rate = 1 − S(100)/N; peak incidence is derived from consecutive S values (new exposures).</p>
      </Card>

      <Card title="Legacy vs household-enabled populations" sub="What differs between the two recorded population runs" right={<Experimental />}>
        <div className="grid gap-4 md:grid-cols-2">
          {(['legacy', 'household'] as const).filter((k) => runs[k]).map((k) => (
            <div key={k} className="rounded-lg border border-line p-3 text-sm">
              <div className="mb-1 font-medium"><Dot color={SCENARIO_COLORS[k]} />{runs[k].label}</div>
              <dl className="grid grid-cols-[auto,1fr] gap-x-3 gap-y-1 text-xs"><dt className="text-mute">Dataset</dt><dd className="num break-all text-right">{runs[k].dataset_id}</dd><dt className="text-mute">CEPOP CRC32</dt><dd className="num text-right">{runs[k].payload_crc32}</dd><dt className="text-mute">Daily checksum</dt><dd className="num text-right">{runs[k].daily_checksum}</dd><dt className="text-mute">Attack rate</dt><dd className="num text-right">{pct(runs[k].summary.attack_rate_pct, 2)}</dd></dl>
            </div>
          ))}
        </div>
        <ul className="mt-3 list-disc space-y-1 pl-5 text-xs leading-relaxed text-ink-2">
          <li><b>Legacy</b>: agents are placed in candidate homes by footprint weight, with no explicit household structure.</li>
          <li><b>Household-enabled</b>: agents are grouped into synthetic households (sizes from an experimental placeholder PMF) that share one candidate home, so many fewer homes are occupied.</li>
          <li>Recorded and identical for both runs: 100,000 agents, simulation seed {runs.legacy.seed}, {runs.legacy.days} days, {runs.legacy.initial_infected} initially infectious. Transmission parameters are not recorded with either run, so equality of transmission settings cannot be verified from the artifacts.</li>
        </ul>
        <div className="mt-3"><Notice>The two populations differ in <b>more than households</b>: their home <i>and</i> destination assignments are different, and the CEPOP inputs are different files. The difference in outcomes is therefore <b>not a controlled causal experiment isolating the effect of households</b>.</Notice></div>
      </Card>

      <Notice tone="info">
        Attack rate is computed here as 1 − S(day 100)/N, i.e. cumulative agents ever exposed (E+I+R). Daily incidence is derived from consecutive S values; the bundle stores no separate incidence column.
        Run integrity: V0 and V6 daily checksum <span className="num">{r.daily_checksum}</span> — {r.v0_v6_equal && r.curves_identical ? 'identical' : 'MISMATCH'}.
      </Notice>
    </div>
  )
}
