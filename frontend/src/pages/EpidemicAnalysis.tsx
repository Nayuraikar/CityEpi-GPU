import { useState } from 'react'
import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Line, LineChart, ReferenceLine, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useApi } from '../api/client'
import type { Runs } from '../api/types'
import { Card, Experimental, Loaded, Notice, PageHeader, Stat, axis, grid, tooltipStyle } from '../components/ui'
import { SCENARIO_COLORS, nf, pct } from '../lib/format'

const COMP = { S: '#4da3ff', E: '#f5b83d', I: '#ff5d6c', R: '#4ad6a0' } as const
const NAMES = { S: 'Susceptible', E: 'Exposed', I: 'Infectious', R: 'Recovered' } as const

export default function EpidemicAnalysis() {
  const s = useApi<Runs>('/api/epidemic')
  return (
    <>
      <PageHeader title="Epidemic Analysis" subtitle="Recorded S/E/I/R trajectories from the V6 CUDA backend (daily checksum equal to the V0 CPU reference)." />
      <Loaded state={s}>{(runs) => <Body runs={runs} />}</Loaded>
    </>
  )
}

function Body({ runs }: { runs: Runs }) {
  const [key, setKey] = useState('baseline')
  const [vis, setVis] = useState({ S: true, E: true, I: true, R: true })
  const [mode, setMode] = useState<'count' | 'share'>('count')
  const r = runs[key], sm = r.summary
  const data = r.curve.map((p) => mode === 'share' ? { ...p, S: p.S / r.agents * 100, E: p.E / r.agents * 100, I: p.I / r.agents * 100, R: p.R / r.agents * 100 } : p)
  const attack = Object.values(runs).map((x) => ({ key: x.key, label: x.label, attack: x.summary.attack_rate_pct }))

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center gap-2">
        {Object.values(runs).map((x) => (
          <button key={x.key} onClick={() => setKey(x.key)}
            className={`rounded-full border px-3 py-1.5 text-xs transition ${key === x.key ? 'border-transparent text-bg' : 'border-line text-mute hover:text-ink'}`}
            style={key === x.key ? { background: SCENARIO_COLORS[x.key] } : undefined}>{x.label}</button>
        ))}
        <span className="ml-auto"><Experimental>Experimental transmission</Experimental></span>
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="Attack rate" value={pct(sm.attack_rate_pct, 2)} sub="1 − S_final/N" color="#ff5d6c" />
        <Stat label="Peak infectious" value={nf(sm.peak_infectious)} sub={`day ${sm.peak_day}`} color="#ff5d6c" />
        <Stat label="Peak daily incidence" value={nf(sm.peak_daily_incidence)} sub={`day ${sm.peak_incidence_day} · new exposures`} color="#f5b83d" />
        <Stat label="Final R" value={nf(sm.final.R)} sub={`${pct(sm.recovered_pct, 2)} of agents`} color="#4ad6a0" />
      </div>

      <Card title="S / E / I / R trajectories" sub={`${r.label} · ${nf(r.agents)} agents · seed ${r.seed} · ${r.initial_infected} initial infectious`}
        right={
          <div className="flex flex-wrap items-center gap-1.5">
            {(Object.keys(COMP) as (keyof typeof COMP)[]).map((c) => (
              <button key={c} onClick={() => setVis({ ...vis, [c]: !vis[c] })} className="rounded-md border px-2 py-0.5 text-xs"
                style={{ borderColor: vis[c] ? COMP[c] : '#1f2b45', color: vis[c] ? COMP[c] : '#8b9ab8' }}>{c}</button>
            ))}
            <button onClick={() => setMode(mode === 'count' ? 'share' : 'count')} className="rounded-md border border-line px-2 py-0.5 text-xs text-mute hover:text-ink">{mode === 'count' ? 'counts' : '% of pop.'}</button>
          </div>}>
        <div className="h-[340px]">
          <ResponsiveContainer>
            <LineChart data={data} margin={{ left: 0, right: 12, top: 22 }}>
              <CartesianGrid {...grid} />
              <XAxis dataKey="day" {...axis} interval={9} label={{ value: 'day', position: 'insideBottomRight', offset: -4, fill: '#8b9ab8', fontSize: 11 }} />
              <YAxis {...axis} tickFormatter={(v) => mode === 'share' ? `${v}%` : Intl.NumberFormat('en', { notation: 'compact' }).format(v)} />
              <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [mode === 'share' ? `${nf(v, 2)}%` : nf(v), NAMES[n as keyof typeof NAMES]]} labelFormatter={(d) => `Day ${d}`} />
              {(Object.keys(COMP) as (keyof typeof COMP)[]).map((c) => vis[c] && <Line key={c} dataKey={c} stroke={COMP[c]} dot={false} strokeWidth={2} isAnimationActive={false} />)}
              <ReferenceLine x={sm.peak_day} stroke="#ff5d6c" strokeDasharray="4 4" label={{ value: 'peak I', fill: '#ff5d6c', fontSize: 10, position: 'top' }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <Card title="Exposed &amp; infectious (zoomed)" sub="E and I on their own scale — the S curve dominates the chart above">
        <div className="h-[240px]">
          <ResponsiveContainer>
            <LineChart data={r.curve} margin={{ left: 0, right: 12, top: 8 }}>
              <CartesianGrid {...grid} />
              <XAxis dataKey="day" {...axis} interval={9} /><YAxis {...axis} />
              <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [nf(v), NAMES[n as keyof typeof NAMES]]} labelFormatter={(d) => `Day ${d}`} />
              <Line dataKey="E" stroke={COMP.E} dot={false} strokeWidth={2} isAnimationActive={false} />
              <Line dataKey="I" stroke={COMP.I} dot={false} strokeWidth={2} isAnimationActive={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <div className="grid gap-5 lg:grid-cols-3">
        <Card title="Daily incidence" sub="New exposures per day = S(t−1) − S(t), derived from recorded S" className="lg:col-span-2">
          <div className="h-[260px]">
            <ResponsiveContainer>
              <AreaChart data={r.curve.slice(1)} margin={{ left: 0, right: 12, top: 8 }}>
                <defs><linearGradient id="inc" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#f5b83d" stopOpacity={0.5} /><stop offset="100%" stopColor="#f5b83d" stopOpacity={0} /></linearGradient></defs>
                <CartesianGrid {...grid} />
                <XAxis dataKey="day" {...axis} /><YAxis {...axis} />
                <Tooltip {...tooltipStyle} formatter={(v: any) => [nf(v), 'New exposures']} labelFormatter={(d) => `Day ${d}`} />
                <Area dataKey="incidence" stroke="#f5b83d" strokeWidth={2} fill="url(#inc)" isAnimationActive={false} />
                <ReferenceLine x={sm.peak_incidence_day} stroke="#f5b83d" strokeDasharray="4 4" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>
        <Card title="Attack rate by run" sub="Cumulative, day 100">
          <div className="h-[260px]">
            <ResponsiveContainer>
              <BarChart data={attack} layout="vertical" margin={{ left: 4, right: 24 }}>
                <CartesianGrid {...grid} horizontal={false} />
                <XAxis type="number" {...axis} unit="%" domain={[0, 100]} />
                <YAxis type="category" dataKey="key" {...axis} width={70} />
                <Tooltip {...tooltipStyle} formatter={(v: any) => [`${nf(v, 2)}%`, 'Attack rate']} />
                <Bar dataKey="attack" radius={[0, 4, 4, 0]} isAnimationActive={false}>
                  {attack.map((a) => <Cell key={a.key} fill={SCENARIO_COLORS[a.key]} fillOpacity={a.key === key ? 1 : 0.45} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <Notice tone="info">
        Attack rate is computed here as 1 − S(day 100)/N, i.e. cumulative agents ever exposed (E+I+R). Daily incidence is derived from consecutive S values; the bundle stores no separate incidence column.
        Run integrity: V0 and V6 daily checksum <span className="num">{r.daily_checksum}</span> — {r.v0_v6_equal && r.curves_identical ? 'identical' : 'MISMATCH'}.
      </Notice>
    </div>
  )
}
