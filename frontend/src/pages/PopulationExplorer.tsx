import { Fragment } from 'react'
import { Bar, BarChart, CartesianGrid, Cell, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useApi } from '../api/client'
import type { DatasetIdentity, PopulationData } from '../api/types'
import { Badge, Card, Dot, Experimental, Loaded, Notice, PageHeader, SectionTitle, Source, Stat, axis, axisLabel, grid, legendStyle, tooltipStyle } from '../components/ui'
import { CAT_COLORS, catLabel, compact, nf, pct } from '../lib/format'
import { C } from '../lib/theme'

export default function PopulationExplorer() {
  const s = useApi<PopulationData>('/api/population')
  return (
    <>
      <PageHeader subtitle="Household structure, home occupancy and destination assignments of the synthetic Bengaluru Urban population. Everything here is generated, not measured: it is not census data." />
      <Loaded state={s}>{(d) => <Body d={d} />}</Loaded>
    </>
  )
}

function Body({ d }: { d: PopulationData }) {
  const a = d.assignment
  const legacy = d.datasets.find((x) => x.kind === 'legacy')
  const hhd = d.datasets.find((x) => x.kind === 'household')
  return (
    <div className="space-y-8">
      <Notice>{d.disclaimers[0]} Household-size assumption: {d.households.assumption}. A “candidate home” is an OpenStreetMap building footprint that the generator <i>may</i> place synthetic agents in; occupied candidate homes are not actual households or dwellings.</Notice>

      <section>
        <SectionTitle title="Dataset identity" sub="Recorded generator outputs, read from each dataset's report.json" right={<Source kind="recorded" />} />
        <div className="grid gap-5 lg:grid-cols-2">{d.datasets.map((x) => <Identity key={x.dataset_id} x={x} primary={x.kind === 'household'} />)}</div>
        <p className="mt-2 text-xs text-mute">The page below describes the household-enabled dataset unless a chart says otherwise. The legacy dataset has no explicit households; its agents are placed in candidate homes by footprint weight, so its occupied-home count is not comparable to a household count.</p>
      </section>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <Stat label="Households" value={nf(d.households.count)} sub={`mean ${nf(d.households.mean_size, 3)} (PMF ${d.households.pmf_mean})`} color={C.lavender} />
        <Stat label="Occupied candidate homes" value={nf(d.home_occupancy.occupied_homes)} sub={`of ${nf(d.home_occupancy.total_homes)} candidate buildings (${pct(100 * d.home_occupancy.occupied_homes / d.home_occupancy.total_homes, 1)})`} color={C.glacier} />
        <Stat label="Destinations used" value={nf(a.destinations_used)} sub={`${nf(a.destinations_at_capacity)} at capacity`} color={C.amber} />
        <Stat label="Median commute" value={`${nf(a.distance_summary_m.p50, 0)} m`} sub={`p95 ${nf(a.distance_summary_m.p95, 0)} m · max ${nf(a.distance_summary_m.max, 0)} m`} color={C.teal} />
        <Stat label="Occupancy Gini" value={nf(a.gini, 3)} sub={`top 1% dest. hold ${pct(a.top1pct_share * 100, 1)}`} color={C.coral} hint="Inequality of agents-per-destination (0 = perfectly even, 1 = all agents in one destination)." />
      </div>

      <section>
        <SectionTitle title="Households & homes" sub="Where agents live" />
        <div className="grid gap-5 lg:grid-cols-2">
          <Card title="Household-size distribution" sub="Observed share vs configured PMF" right={<Experimental>Placeholder PMF</Experimental>}>
            <div className="h-[280px]"><ResponsiveContainer>
              <BarChart data={d.households.histogram.map((h) => ({ ...h, obs: h.observed_share * 100, cfg: h.configured_pmf * 100 }))}>
                <CartesianGrid {...grid} vertical={false} /><XAxis dataKey="size" {...axis} label={{ ...axisLabel('members'), position: 'insideBottom', offset: -2 }} /><YAxis {...axis} unit="%" />
                <Tooltip {...tooltipStyle} formatter={(v: any) => `${nf(v, 2)}%`} labelFormatter={(s) => `${s} members`} /><Legend verticalAlign="top" height={30} wrapperStyle={legendStyle} />
                <Bar dataKey="obs" name="Observed" fill={C.lavender} radius={[4, 4, 0, 0]} isAnimationActive={false} />
                <Bar dataKey="cfg" name="Configured PMF" fill={C.lavender + '55'} radius={[4, 4, 0, 0]} isAnimationActive={false} />
              </BarChart></ResponsiveContainer></div>
            <p className="mt-2 text-xs text-mute">Households per size: {d.households.histogram.map((h) => `${h.size}: ${nf(h.households)}`).join(' · ')}</p>
          </Card>

          <Card title="Home occupancy" sub={`Agents per home building · ${nf(d.home_occupancy.unused_homes)} candidate homes unused (0 agents)`}>
            <div className="h-[280px]"><ResponsiveContainer>
              <BarChart data={d.home_occupancy.histogram.filter((h) => h.bucket !== '0')}>
                <CartesianGrid {...grid} vertical={false} /><XAxis dataKey="bucket" {...axis} label={{ ...axisLabel('agents in home'), position: 'insideBottom', offset: -2 }} /><YAxis {...axis} tickFormatter={compact} />
                <Tooltip {...tooltipStyle} formatter={(v: any) => [nf(v), 'homes']} labelFormatter={(b) => `${b} agents`} />
                <Bar dataKey="homes" fill={C.glacier} radius={[4, 4, 0, 0]} isAnimationActive={false} />
              </BarChart></ResponsiveContainer></div>
            <p className="mt-2 text-xs text-mute">Zero-occupancy bucket omitted from chart ({nf(d.home_occupancy.unused_homes)} homes). Each occupied building holds {nf(d.home_occupancy.households_per_occupied_building.max)} household (configured cap {d.home_occupancy.households_per_building_cap} per building; {nf(d.home_occupancy.buildings_at_household_cap)} buildings reached it).</p>
          </Card>
        </div>
      </section>

      <section>
        <SectionTitle title="Destinations & commuting" sub="Where agents go, and how far" />
        <div className="grid gap-5 lg:grid-cols-2">
          <Card title="Destination assignments by category" sub="Agents assigned vs destination capacity (capacity = placeholder)" right={<Experimental>Placeholder capacity</Experimental>}>
            <div className="h-[300px]"><ResponsiveContainer>
              <BarChart data={d.destinations.by_category} layout="vertical" margin={{ left: 30 }}>
                <CartesianGrid {...grid} horizontal={false} /><XAxis type="number" {...axis} tickFormatter={compact} />
                <YAxis type="category" dataKey="category" {...axis} width={110} tickFormatter={catLabel} />
                <Tooltip {...tooltipStyle} formatter={(v: any) => nf(v)} labelFormatter={(c) => catLabel(String(c))} /><Legend wrapperStyle={legendStyle} />
                <Bar dataKey="occupancy" name="Agents assigned" fill={C.terracotta} radius={[0, 4, 4, 0]} isAnimationActive={false}>{d.destinations.by_category.map((c) => <Cell key={c.category} fill={CAT_COLORS[c.category]} />)}</Bar>
                <Bar dataKey="capacity" name="Capacity" fill={C.slate + '40'} radius={[0, 4, 4, 0]} isAnimationActive={false} />
              </BarChart></ResponsiveContainer></div>
          </Card>

          <Card title="Assignment distance" sub="Home → destination distance in metres (haversine, from agents.parquet), agents per bin" right={<Experimental>Synthetic assignment</Experimental>}>
            <div className="h-[300px]"><ResponsiveContainer>
              <BarChart data={a.distance_histogram.map((h, i) => ({ ...h, legacy: legacy?.distance_histogram[i]?.agents }))}>
                <CartesianGrid {...grid} vertical={false} /><XAxis dataKey="bin" {...axis} interval={0} angle={-30} textAnchor="end" height={50} fontSize={10} /><YAxis {...axis} tickFormatter={compact} />
                <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [nf(v), n]} /><Legend verticalAlign="top" height={30} wrapperStyle={legendStyle} />
                <Bar dataKey="agents" name="Household-enabled" fill={C.teal} radius={[4, 4, 0, 0]} isAnimationActive={false} />
                {legacy && <Bar dataKey="legacy" name="Legacy" fill={C.lavender + '99'} radius={[4, 4, 0, 0]} isAnimationActive={false} />}
              </BarChart></ResponsiveContainer></div>
            <p className="mt-2 text-xs text-mute">Placement stages: {a.stages.map((s) => `stage ${s.stage}${s.radius_m ? ` (≤${nf(s.radius_m / 1000)} km)` : ''}: ${nf(s.agents)}`).join(' · ')}</p>
          </Card>
        </div>
      </section>

      <Card title="Assignment distance by destination category" sub="Median and 95th-percentile home → destination distance, household-enabled dataset (metres)">
        <div className="h-[260px]"><ResponsiveContainer>
          <BarChart data={a.distance_by_category}>
            <CartesianGrid {...grid} vertical={false} /><XAxis dataKey="category" {...axis} tickFormatter={catLabel} interval={0} fontSize={10} /><YAxis {...axis} unit=" m" width={56} />
            <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [`${nf(v, 0)} m`, n]} labelFormatter={(c) => `${catLabel(String(c))} · ${nf(a.distance_by_category.find((x) => x.category === c)?.count)} agents`} /><Legend verticalAlign="top" height={30} wrapperStyle={legendStyle} />
            <Bar dataKey="median" name="Median" fill={C.teal} radius={[4, 4, 0, 0]} isAnimationActive={false} />
            <Bar dataKey="p95" name="95th percentile" fill={C.amber} radius={[4, 4, 0, 0]} isAnimationActive={false} />
          </BarChart></ResponsiveContainer></div>
        {hhd && <p className="mt-2 text-xs text-mute">Overall: mean {nf(hhd.distance_m.mean, 0)} m · median {nf(hhd.distance_m.p50, 0)} m · p95 {nf(hhd.distance_m.p95, 0)} m · max {nf(hhd.distance_m.max, 0)} m. Destinations are placeholder OSM-derived places with experimental capacities, so these are properties of the generator, not observed commuting.</p>}
      </Card>

      <section>
        <SectionTitle title="Detail tables" />
        <div className="grid gap-5 lg:grid-cols-2">
          <Card title="Category detail">
            <div className="overflow-x-auto"><table className="tbl">
              <thead><tr className="text-left"><th>Category</th><th className="text-right">Dest.</th><th className="text-right">Used</th><th className="text-right">Agents</th><th className="text-right">Util.</th><th className="text-right">Median m</th><th className="text-right">p95 m</th></tr></thead>
              <tbody>{d.destinations.by_category.map((c) => {
                const dc = a.distance_by_category.find((x) => x.category === c.category)
                return (<tr key={c.category}><td><Dot color={CAT_COLORS[c.category]} />{catLabel(c.category)}</td>
                  <td className="num text-right">{nf(c.destinations)}</td><td className="num text-right">{nf(c.used)}</td><td className="num text-right">{nf(c.occupancy)}</td><td className="num text-right">{pct(c.utilisation_pct, 1)}</td><td className="num text-right">{nf(dc?.median, 0)}</td><td className="num text-right">{nf(dc?.p95, 0)}</td></tr>)
              })}</tbody>
            </table></div>
          </Card>
          <Card title="Most-occupied destinations" sub={`Destination occupancy max ${d.destinations.nonzero.max} · ${nf(d.destinations.unused_destinations)} destinations unused`}>
            <div className="overflow-x-auto"><table className="tbl tbl-sm">
              <thead><tr className="text-left"><th>Name</th><th>Category</th><th className="text-right">Agents</th><th className="text-right">Capacity</th></tr></thead>
              <tbody>{d.destinations.top.slice(0, 10).map((t) => (
                <tr key={t.location_id}><td className="max-w-[200px] truncate" title={t.name ?? undefined}>{t.name ?? <span className="text-mute">unnamed #{t.location_id}</span>}</td><td className="text-mute"><Dot color={CAT_COLORS[t.category]} />{catLabel(t.category)}</td><td className="num text-right">{t.occupancy}</td><td className="num text-right">{t.capacity}</td></tr>))}</tbody>
            </table></div>
          </Card>
        </div>
      </section>
    </div>
  )
}

function Identity({ x, primary }: { x: DatasetIdentity; primary: boolean }) {
  const rows: [string, React.ReactNode][] = [
    ['Dataset ID', <span className="num break-all text-xs">{x.dataset_id}</span>],
    ['Agents (synthetic)', nf(x.agents)],
    ['Candidate homes → occupied', `${nf(x.candidate_homes)} → ${nf(x.occupied_homes)}`],
    ['Households', x.households == null ? <span className="text-mute">not modelled</span> : `${nf(x.households)} (mean size ${nf(x.mean_household_size, 3)})`],
    ['Destinations → used', `${nf(x.destinations)} → ${nf(x.destinations_used)}`],
    ['Mean / median commute', `${nf(x.distance_m.mean, 0)} m / ${nf(x.distance_m.p50, 0)} m`],
    ['Independent validation', x.validation.passed ? `${x.validation.n_checks}/${x.validation.n_checks} checks passed` : 'checks failed'],
    ['Generator · seed', `${x.tool_version} · ${x.seed}`],
    ['CEPOP CRC32', <span className="num text-xs">{x.cepop_crc32}</span>],
    ['Config SHA-256', <span className="num text-xs">{x.config_sha256.slice(0, 16)}…</span>],
  ]
  return (
    <Card title={x.label} right={<Badge color={primary ? C.teal : C.lavender}>{primary ? 'shown below' : 'comparison'}</Badge>}>
      <dl className="grid grid-cols-[auto,1fr] gap-x-4 gap-y-1.5 text-sm">{rows.map(([k, v]) => <Fragment key={k}><dt className="text-mute">{k}</dt><dd className="text-right font-medium">{v}</dd></Fragment>)}</dl>
    </Card>
  )
}
