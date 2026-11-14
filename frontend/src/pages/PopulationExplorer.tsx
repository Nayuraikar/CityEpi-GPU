import { Bar, BarChart, CartesianGrid, Cell, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useApi } from '../api/client'
import type { PopulationData } from '../api/types'
import { Card, Experimental, Loaded, Notice, PageHeader, Stat, axis, grid, tooltipStyle } from '../components/ui'
import { CAT_COLORS, catLabel, nf, pct } from '../lib/format'

export default function PopulationExplorer() {
  const s = useApi<PopulationData>('/api/population')
  return (
    <>
      <PageHeader title="Population Explorer" subtitle="Household structure, home occupancy and destination assignments of the synthetic Bengaluru Urban population." />
      <Loaded state={s}>{(d) => <Body d={d} />}</Loaded>
    </>
  )
}

function Body({ d }: { d: PopulationData }) {
  const a = d.assignment
  return (
    <div className="space-y-5">
      <Notice>{d.disclaimers[0]} Household-size assumption: {d.households.assumption}.</Notice>
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        <Stat label="Households" value={nf(d.households.count)} sub={`mean ${nf(d.households.mean_size, 3)} (PMF ${d.households.pmf_mean})`} color="#a78bfa" />
        <Stat label="Occupied homes" value={nf(d.home_occupancy.occupied_homes)} sub={`of ${nf(d.home_occupancy.total_homes)} candidate buildings`} color="#4da3ff" />
        <Stat label="Destinations used" value={nf(a.destinations_used)} sub={`${nf(a.destinations_at_capacity)} at capacity`} color="#f5b83d" />
        <Stat label="Median commute" value={`${nf(a.distance_summary_m.p50, 0)} m`} sub={`p95 ${nf(a.distance_summary_m.p95, 0)} m · max ${nf(a.distance_summary_m.max, 0)} m`} color="#5eead4" />
        <Stat label="Occupancy Gini" value={nf(a.gini, 3)} sub={`top 1% dest. hold ${pct(a.top1pct_share * 100, 1)}`} color="#ff5d6c" />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Household-size distribution" sub="Observed share vs configured PMF" right={<Experimental>Placeholder PMF</Experimental>}>
          <div className="h-[280px]"><ResponsiveContainer>
            <BarChart data={d.households.histogram.map((h) => ({ ...h, obs: h.observed_share * 100, cfg: h.configured_pmf * 100 }))}>
              <CartesianGrid {...grid} /><XAxis dataKey="size" {...axis} label={{ value: 'members', position: 'insideBottom', offset: -2, fill: '#8b9ab8', fontSize: 11 }} /><YAxis {...axis} unit="%" />
              <Tooltip {...tooltipStyle} formatter={(v: any) => `${nf(v, 2)}%`} /><Legend wrapperStyle={{ fontSize: 12 }} />
              <Bar dataKey="obs" name="Observed" fill="#a78bfa" radius={[4, 4, 0, 0]} isAnimationActive={false} />
              <Bar dataKey="cfg" name="Configured PMF" fill="#a78bfa55" radius={[4, 4, 0, 0]} isAnimationActive={false} />
            </BarChart></ResponsiveContainer></div>
          <p className="mt-2 text-xs text-mute">Households per size: {d.households.histogram.map((h) => `${h.size}: ${nf(h.households)}`).join(' · ')}</p>
        </Card>

        <Card title="Home occupancy" sub={`Agents per home building · ${nf(d.home_occupancy.unused_homes)} candidate homes unused (0 agents)`}>
          <div className="h-[280px]"><ResponsiveContainer>
            <BarChart data={d.home_occupancy.histogram.filter((h) => h.bucket !== '0')}>
              <CartesianGrid {...grid} /><XAxis dataKey="bucket" {...axis} label={{ value: 'agents in home', position: 'insideBottom', offset: -2, fill: '#8b9ab8', fontSize: 11 }} /><YAxis {...axis} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => nf(v)} />
              <Bar dataKey="homes" fill="#4da3ff" radius={[4, 4, 0, 0]} isAnimationActive={false} />
            </BarChart></ResponsiveContainer></div>
          <p className="mt-2 text-xs text-mute">Zero-occupancy bucket omitted from chart ({nf(d.home_occupancy.unused_homes)} homes). Each occupied building holds exactly one household (cap 4 per building).</p>
        </Card>

        <Card title="Destination assignments by category" sub="Agents assigned vs destination capacity (capacity = placeholder)" right={<Experimental>Placeholder capacity</Experimental>}>
          <div className="h-[300px]"><ResponsiveContainer>
            <BarChart data={d.destinations.by_category} layout="vertical" margin={{ left: 30 }}>
              <CartesianGrid {...grid} horizontal={false} /><XAxis type="number" {...axis} tickFormatter={(v) => Intl.NumberFormat('en', { notation: 'compact' }).format(v)} />
              <YAxis type="category" dataKey="category" {...axis} width={110} tickFormatter={catLabel} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => nf(v)} /><Legend wrapperStyle={{ fontSize: 12 }} />
              <Bar dataKey="occupancy" name="Agents assigned" fill="#fb923c" radius={[0, 4, 4, 0]} isAnimationActive={false}>{d.destinations.by_category.map((c) => <Cell key={c.category} fill={CAT_COLORS[c.category]} />)}</Bar>
              <Bar dataKey="capacity" name="Capacity" fill="#8b9ab833" radius={[0, 4, 4, 0]} isAnimationActive={false} />
            </BarChart></ResponsiveContainer></div>
        </Card>

        <Card title="Assignment distance" sub="Home → destination distance (EPSG:4326 haversine, from agents.parquet)">
          <div className="h-[300px]"><ResponsiveContainer>
            <BarChart data={a.distance_histogram}>
              <CartesianGrid {...grid} /><XAxis dataKey="bin" {...axis} interval={0} angle={-30} textAnchor="end" height={50} fontSize={10} /><YAxis {...axis} tickFormatter={(v) => Intl.NumberFormat('en', { notation: 'compact' }).format(v)} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => [nf(v), 'agents']} />
              <Bar dataKey="agents" fill="#5eead4" radius={[4, 4, 0, 0]} isAnimationActive={false} />
            </BarChart></ResponsiveContainer></div>
          <p className="mt-2 text-xs text-mute">Placement stages: {a.stages.map((s) => `stage ${s.stage}${s.radius_m ? ` (≤${nf(s.radius_m / 1000)} km)` : ''}: ${nf(s.agents)}`).join(' · ')}</p>
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Category detail">
          <div className="overflow-x-auto"><table className="w-full text-sm">
            <thead><tr className="label text-left"><th className="pb-2">Category</th><th className="pb-2 text-right">Dest.</th><th className="pb-2 text-right">Used</th><th className="pb-2 text-right">Agents</th><th className="pb-2 text-right">Util.</th><th className="pb-2 text-right">Median m</th><th className="pb-2 text-right">p95 m</th></tr></thead>
            <tbody>{d.destinations.by_category.map((c) => {
              const dc = a.distance_by_category.find((x) => x.category === c.category)
              return (<tr key={c.category} className="border-t border-line"><td className="py-2"><span className="mr-2 inline-block h-2 w-2 rounded-full" style={{ background: CAT_COLORS[c.category] }} />{catLabel(c.category)}</td>
                <td className="num text-right">{nf(c.destinations)}</td><td className="num text-right">{nf(c.used)}</td><td className="num text-right">{nf(c.occupancy)}</td><td className="num text-right">{pct(c.utilisation_pct, 1)}</td><td className="num text-right">{nf(dc?.median, 0)}</td><td className="num text-right">{nf(dc?.p95, 0)}</td></tr>)
            })}</tbody>
          </table></div>
        </Card>
        <Card title="Most-occupied destinations" sub={`Destination occupancy max ${d.destinations.nonzero.max} · ${nf(d.destinations.unused_destinations)} destinations unused`}>
          <div className="overflow-x-auto"><table className="w-full text-sm">
            <thead><tr className="label text-left"><th className="pb-2">Name</th><th className="pb-2">Category</th><th className="pb-2 text-right">Agents</th><th className="pb-2 text-right">Capacity</th></tr></thead>
            <tbody>{d.destinations.top.slice(0, 10).map((t) => (
              <tr key={t.location_id} className="border-t border-line"><td className="max-w-[200px] truncate py-1.5">{t.name ?? <span className="text-mute">unnamed #{t.location_id}</span>}</td><td className="text-mute">{catLabel(t.category)}</td><td className="num text-right">{t.occupancy}</td><td className="num text-right">{t.capacity}</td></tr>))}</tbody>
          </table></div>
        </Card>
      </div>
    </div>
  )
}
