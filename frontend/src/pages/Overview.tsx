import { CheckCircle2, CircleDashed, CircleSlash, MinusCircle } from 'lucide-react'
import { useApi } from '../api/client'
import type { Overview as O } from '../api/types'
import { Badge, Card, Experimental, Loaded, Notice, PageHeader, Stat } from '../components/ui'
import { SCENARIO_COLORS, catLabel, nf, pct, secs } from '../lib/format'

const STATE: Record<string, { icon: any; color: string; label: string }> = {
  complete: { icon: CheckCircle2, color: '#4ad6a0', label: 'Complete' },
  partial: { icon: CircleDashed, color: '#f5b83d', label: 'Partial' },
  gap: { icon: MinusCircle, color: '#f5b83d', label: 'Not recorded' },
  'not-implemented': { icon: CircleSlash, color: '#8b9ab8', label: 'Not implemented' },
}

export default function Overview() {
  const s = useApi<O>('/api/overview')
  return (
    <>
      <PageHeader title="Project Overview" subtitle="Synthetic Bengaluru Urban population, recorded epidemic runs, and verified CPU↔GPU equivalence." />
      <Loaded state={s}>{(d) => <Body d={d} />}</Loaded>
    </>
  )
}

function Body({ d }: { d: O }) {
  const p = d.population, c = d.configuration, h = d.epidemic.household
  return (
    <div className="space-y-6">
      <Notice>{p.disclaimers[0]} {p.disclaimers[2]}</Notice>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        <Stat label="Agents" value={nf(p.agents)} sub="synthetic" />
        <Stat label="Locations" value={nf(p.locations)} sub={`${nf(p.homes)} homes · ${nf(p.destinations)} dest.`} color="#4da3ff" />
        <Stat label="Households" value={nf(p.households)} sub={`mean size ${nf(p.mean_household_size, 2)}`} color="#a78bfa" />
        <Stat label="Mean commute" value={`${nf(p.mean_commute_m, 0)} m`} sub="agent → destination" color="#f5b83d" />
        <Stat label="Pop. validation" value={`${p.validation.n_checks - (p.validation.passed ? 0 : 1)}/${p.validation.n_checks}`} sub={p.validation.passed ? 'independent checks passed' : 'checks failed'} color="#4ad6a0" />
        <Stat label="V0 ≡ V6" value={Object.values(d.epidemic).every((e) => e.v0_v6_equal) ? 'Equal' : 'Differs'} sub={`${Object.keys(d.epidemic).length} scenarios, daily checksum`} color="#5eead4" />
      </div>

      <div>
        <div className="mb-2 flex items-center gap-2"><h2 className="text-sm font-semibold">Epidemic KPIs — household population, baseline transmission</h2><Experimental /></div>
        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          <Stat label="Attack rate" value={pct(h.attack_rate_pct, 1)} sub="1 − S_final / N (cumulative)" color="#ff5d6c" />
          <Stat label="Peak infectious" value={nf(h.peak_infectious)} sub={`day ${h.peak_day}`} color="#ff5d6c" />
          <Stat label="Peak daily incidence" value={nf(h.peak_daily_incidence)} sub={`day ${h.peak_incidence_day}`} color="#f5b83d" />
          <Stat label="Recovered @ day 100" value={pct(h.recovered_pct, 1)} sub={`${nf(h.final.R)} agents`} color="#4ad6a0" />
        </div>
      </div>

      <div className="grid gap-4 xl:grid-cols-3">
        <Card title="Simulation configuration" sub={`Seed ${c.sim_seed} · ${c.sim_days} days · ${c.initial_infected} initially infected`} right={<Experimental />} className="xl:col-span-1">
          <dl className="grid grid-cols-[auto,1fr] gap-x-4 gap-y-2 text-sm">
            <Row k="Population seed" v={c.seed} />
            <Row k="Households per building cap" v={c.max_households_per_building} />
            <Row k="Residential tiers" v={c.residential_tiers.join(', ')} />
            <Row k="Assignment kernel" v={`${c.assignment_kernel.type}, scale ${nf(c.assignment_kernel.scale_m)} m`} />
            <Row k="Candidate K / radius" v={`${c.candidate_k} / ${nf(c.radius_m)} m`} />
            <Row k="Capacity slack" v={c.capacity_slack} />
            <Row k="Config SHA-256" v={<span className="num text-xs">{c.config_sha256.slice(0, 16)}…</span>} />
            <Row k="CEPOP CRC32" v={<span className="num text-xs">{p.cepop_crc32}</span>} />
          </dl>
          <div className="mt-3">
            <div className="label mb-1.5">Destination categories</div>
            <div className="flex flex-wrap gap-1.5">{c.destination_categories.map((k: string) => <Badge key={k}>{catLabel(k)}</Badge>)}</div>
          </div>
          <div className="mt-3">
            <div className="label mb-1.5">Household size PMF (placeholder)</div>
            <div className="flex gap-1.5">
              {Object.entries(c.household_size_pmf).map(([k, v]) => (
                <div key={k} className="flex-1 rounded-md bg-panel2 px-1 py-1.5 text-center"><div className="text-[10px] text-mute">{k}</div><div className="num text-xs">{nf((v as number) * 100, 0)}%</div></div>
              ))}
            </div>
          </div>
        </Card>

        <Card title="Scenario snapshot" sub="Recorded runs, seed 42" className="xl:col-span-1">
          <table className="w-full text-sm">
            <thead><tr className="label text-left"><th className="pb-2">Scenario</th><th className="px-2 pb-2 text-right">Attack</th><th className="px-2 pb-2 text-right">Peak I</th><th className="pb-2 text-right">Peak&nbsp;day</th></tr></thead>
            <tbody>
              {Object.entries(d.epidemic).map(([k, e]) => (
                <tr key={k} className="border-t border-line">
                  <td className="py-2"><span className="mr-2 inline-block h-2 w-2 rounded-full" style={{ background: SCENARIO_COLORS[k] }} />{e.label}</td>
                  <td className="num px-2 text-right">{pct(e.attack_rate_pct, 2)}</td>
                  <td className="num px-2 text-right">{nf(e.peak_infectious)}</td>
                  <td className="num text-right">{e.peak_day}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="mt-3 text-xs text-mute">The household-population run and the baseline-transmission run are the same recorded configuration (identical curves).</p>
        </Card>

        <Card title="Project status" sub="What the bundle does and does not contain" className="xl:col-span-1">
          <ul className="space-y-3">
            {d.status.map((s) => {
              const m = STATE[s.state] ?? STATE.partial, Icon = m.icon
              return (
                <li key={s.item} className="flex gap-2.5">
                  <Icon size={16} className="mt-0.5 shrink-0" style={{ color: m.color }} />
                  <div><div className="text-sm">{s.item}</div><div className="text-xs text-mute">{s.detail}</div></div>
                </li>
              )
            })}
          </ul>
        </Card>
      </div>
      <p className="text-xs text-mute">Recorded on {d.run_environment.gpu} · pipeline verdict {d.run_environment.verdict} · generated {d.run_environment.generated_utc?.slice(0, 10)}</p>
    </div>
  )
}

const Row = ({ k, v }: { k: string; v: any }) => (<><dt className="text-mute">{k}</dt><dd className="text-right">{v}</dd></>)
