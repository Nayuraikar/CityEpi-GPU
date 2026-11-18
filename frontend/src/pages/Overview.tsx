import { ArrowRight, CheckCircle2, CircleDashed, CircleSlash, MinusCircle, ShieldCheck } from 'lucide-react'
import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useApi } from '../api/client'
import type { Async } from '../api/client'
import type { Overview as O, Runs } from '../api/types'
import { Badge, Card, Dot, Experimental, Loaded, Notice, PageHeader, SectionTitle, Source, Stat, axis, grid, tooltipStyle } from '../components/ui'
import { CAT_COLORS, SCENARIO_COLORS, catLabel, compact, nf, pct } from '../lib/format'
import { C, SEIR, SEIR_NAMES } from '../lib/theme'

const STATE: Record<string, { icon: any; color: string; label: string }> = {
  complete: { icon: CheckCircle2, color: C.sage, label: 'Complete' },
  partial: { icon: CircleDashed, color: C.amber, label: 'Partial' },
  gap: { icon: MinusCircle, color: C.amber, label: 'Not recorded' },
  'not-implemented': { icon: CircleSlash, color: C.slate, label: 'Not implemented' },
}

export default function Overview() {
  const s = useApi<O>('/api/overview')
  return (
    <>
      <PageHeader subtitle="Synthetic Bengaluru Urban population, recorded epidemic runs, and verified CPU↔GPU equivalence. Cards are labelled as recorded results; only the Simulation Studio runs live simulations." />
      <Loaded state={s}>{(d) => <Body d={d} />}</Loaded>
    </>
  )
}

function Body({ d }: { d: O }) {
  const p = d.population, c = d.configuration, h = d.epidemic.household
  const runs = useApi<Runs>('/api/epidemic')
  const allEqual = Object.values(d.epidemic).every((e) => e.v0_v6_equal)
  const maxAttack = Math.max(...Object.values(d.epidemic).map((e) => e.attack_rate_pct), 1)
  const pmf = Object.entries(c.household_size_pmf) as [string, number][]
  const pmfMax = Math.max(...pmf.map(([, v]) => v))

  return (
    <div className="space-y-8">
      <Notice>{p.disclaimers[0]} {p.disclaimers[2]}</Notice>

      <BackendStatus />

      <section>
        <SectionTitle title="Synthetic population" sub="Generated from OpenStreetMap-derived locations with experimental household assumptions" right={<Source kind="recorded" />} />
        <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
          <Stat label="Agents" value={nf(p.agents)} sub="synthetic" color={C.teal} />
          <Stat label="Locations" value={nf(p.locations)} sub={`${nf(p.homes)} homes · ${nf(p.destinations)} dest.`} color={C.glacier} />
          <Stat label="Households" value={nf(p.households)} sub={`mean size ${nf(p.mean_household_size, 2)} · synthetic`} color={C.lavender} />
          <Stat label="Mean commute" value={`${nf(p.mean_commute_m, 0)} m`} sub="agent → destination" color={C.amber} />
          <Stat label="Pop. validation" value={p.validation.passed ? `${p.validation.n_checks}/${p.validation.n_checks}` : 'Failed'} sub={`household dataset · legacy ${p.legacy_validation.passed ? `${p.legacy_validation.n_checks}/${p.legacy_validation.n_checks}` : 'failed'}`} color={C.sage} hint="Independent validation checks recorded in each dataset's report.json. They check internal consistency of the generated data, not agreement with real Bengaluru." />
          <Stat label="V0 ≡ V6" value={allEqual ? 'Equal' : 'Differs'} sub={`${Object.keys(d.epidemic).length} scenarios, daily checksum`} color={C.teal} hint="The CPU reference (V0) and CUDA backend (V6) produce identical daily S/E/I/R checksums for each recorded scenario." />
        </div>
      </section>

      <section>
        <SectionTitle title="Epidemic outcome" sub="Household population · baseline transmission · seed 42" right={<span className="flex gap-1.5"><Source kind="recorded" /><Experimental /></span>} />
        <div className="grid gap-4 lg:grid-cols-5">
          <div className="grid grid-cols-2 gap-3 lg:col-span-2">
            <Stat label="Attack rate" value={pct(h.attack_rate_pct, 1)} sub="1 − S_final / N (cumulative)" color={C.coral} />
            <Stat label="Peak infectious" value={nf(h.peak_infectious)} sub={`day ${h.peak_day}`} color={C.coral} />
            <Stat label="Peak daily incidence" value={nf(h.peak_daily_incidence)} sub={`day ${h.peak_incidence_day}`} color={C.amber} />
            <Stat label="Recovered @ day 100" value={pct(h.recovered_pct, 1)} sub={`${nf(h.final.R)} agents`} color={C.sage} />
          </div>
          <Card title="Trajectory preview" sub="Household population, recorded S/E/I/R (full analysis on the Epidemic page)" className="lg:col-span-3">
            <div className="h-[210px]">
              {runs.data?.household ? (
                <ResponsiveContainer>
                  <LineChart data={runs.data.household.curve} margin={{ left: 0, right: 8, top: 6 }}>
                    <CartesianGrid {...grid} />
                    <XAxis dataKey="day" {...axis} interval={19} /><YAxis {...axis} tickFormatter={compact} width={42} />
                    <Tooltip {...tooltipStyle} formatter={(v: any, n: any) => [nf(v), SEIR_NAMES[n as keyof typeof SEIR_NAMES]]} labelFormatter={(x) => `Day ${x}`} />
                    {(['S', 'E', 'I', 'R'] as const).map((k) => <Line key={k} dataKey={k} stroke={SEIR[k]} strokeWidth={2} dot={false} isAnimationActive={false} />)}
                  </LineChart>
                </ResponsiveContainer>
              ) : <div className="skeleton h-full" />}
            </div>
            <div className="mt-2 flex flex-wrap gap-3 text-xs text-mute">{(['S', 'E', 'I', 'R'] as const).map((k) => <span key={k}><Dot color={SEIR[k]} />{SEIR_NAMES[k]}</span>)}</div>
          </Card>
        </div>
      </section>

      <div className="grid gap-5 xl:grid-cols-3">
        <Card title="Scenario snapshot" sub="Recorded runs, seed 42 · bar = attack rate">
          <div className="overflow-x-auto"><table className="tbl">
            <thead><tr className="text-left"><th>Scenario</th><th className="px-2 text-right">Attack</th><th className="px-2 text-right">Peak I</th><th className="text-right">Peak&nbsp;day</th></tr></thead>
            <tbody>
              {Object.entries(d.epidemic).map(([k, e]) => (
                <tr key={k}>
                  <td className="py-2.5">
                    <div className="flex items-center"><Dot color={SCENARIO_COLORS[k]} />{e.label}</div>
                    <div className="mt-1.5 h-1 overflow-hidden rounded-full bg-surface-3"><div className="h-full rounded-full transition-all duration-700" style={{ width: `${(e.attack_rate_pct / maxAttack) * 100}%`, background: SCENARIO_COLORS[k] }} /></div>
                  </td>
                  <td className="num px-2 text-right align-top pt-2.5">{pct(e.attack_rate_pct, 2)}</td>
                  <td className="num px-2 text-right align-top pt-2.5">{nf(e.peak_infectious)}</td>
                  <td className="num text-right align-top pt-2.5">{e.peak_day}</td>
                </tr>
              ))}
            </tbody>
          </table></div>
          <p className="mt-3 text-xs text-mute">The household-population run and the baseline-transmission run are the same recorded configuration (identical curves).</p>
        </Card>

        <Card title="Simulation configuration" sub={`Seed ${c.sim_seed} · ${c.sim_days} days · ${c.initial_infected} initially infected`} right={<Experimental />}>
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
          <div className="mt-4 border-t border-line pt-4">
            <div className="label mb-2">Household size PMF (placeholder)</div>
            <div className="flex h-20 items-end gap-2">
              {pmf.map(([k, v]) => (
                <div key={k} className="group flex flex-1 flex-col items-center gap-1" title={`${k} members: ${nf(v * 100, 0)}% (configured)`}>
                  <span className="num text-[10px] text-mute">{nf(v * 100, 0)}%</span>
                  <div className="w-full rounded-t-md bg-lavender/70 transition-colors group-hover:bg-lavender" style={{ height: `${Math.max((v / pmfMax) * 52, 3)}px` }} />
                  <span className="text-[10px] text-mute">{k}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="mt-4">
            <div className="label mb-2">Destination categories</div>
            <div className="flex flex-wrap gap-1.5">{c.destination_categories.map((k: string) => <Badge key={k} color={CAT_COLORS[k] ?? C.slate}>{catLabel(k)}</Badge>)}</div>
          </div>
        </Card>

        <Card title="Project status" sub="What the bundle does and does not contain">
          <ul className="space-y-1">
            {d.status.map((s) => {
              const m = STATE[s.state] ?? STATE.partial, Icon = m.icon
              return (
                <li key={s.item} className="flex gap-3 rounded-lg p-2 transition-colors hover:bg-surface-2" title={m.label}>
                  <Icon size={16} className="mt-0.5 shrink-0" style={{ color: m.color }} />
                  <div className="min-w-0"><div className="flex items-center gap-2 text-sm font-medium">{s.item}<span className="rounded px-1 py-px text-[9px] font-semibold uppercase tracking-wide" style={{ background: m.color + '22', color: C.ink }}>{m.label}</span></div><div className="text-xs leading-relaxed text-mute">{s.detail}</div></div>
                </li>
              )
            })}
          </ul>
        </Card>
      </div>

      <section>
        <SectionTitle title="Architecture" sub="How the pieces fit together" />
        <div className="grid gap-5 lg:grid-cols-2">
          <Card title="Pipeline">
            <ol className="space-y-2.5 text-sm text-ink-2">
              {ARCH.map(([t, dsc], i) => <li key={t} className="flex gap-3"><span className="num mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full bg-teal-50 text-[11px] font-semibold text-teal-700">{i + 1}</span><span><b className="text-ink">{t}</b> — {dsc}</span></li>)}
            </ol>
          </Card>
          <Card title="Recorded results vs live simulation">
            <ul className="space-y-3 text-sm text-ink-2">
              <li><Source kind="recorded" /> <span className="ml-1">Overview, GIS, Population, Epidemic, Scenario and PAGP pages read files stored in <code>ui_data_bundle/</code> through read-only endpoints. Nothing on them is recomputed by a simulation.</span></li>
              <li><Source kind="live" /> <span className="ml-1">Only the Simulation Studio launches <code>extpop_run</code> on this host. Its runs are stored separately and never overwrite recorded results.</span></li>
              <li className="text-xs text-mute">V5/V6 CUDA numbers were recorded on Kaggle (Tesla T4). The ten-seed validation is V0 CPU only. Household figures are synthetic, not census data.</li>
            </ul>
          </Card>
        </div>
      </section>

      <section>
        <SectionTitle title="Detailed pages" />
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {LINKS.map(([id, t, dsc]) => (
            <a key={id} href={`#${id}`} className="card card-hover group flex items-start justify-between gap-3 p-4">
              <span><span className="block text-sm font-semibold text-ink">{t}</span><span className="mt-0.5 block text-xs leading-relaxed text-mute">{dsc}</span></span>
              <ArrowRight size={15} className="mt-0.5 shrink-0 text-mute transition group-hover:translate-x-0.5 group-hover:text-teal-600" />
            </a>
          ))}
        </div>
      </section>

      <p className="flex items-center gap-1.5 text-xs text-mute"><ShieldCheck size={13} className="text-teal-600" /> Recorded on {d.run_environment.gpu} · pipeline verdict {d.run_environment.verdict} · generated {d.run_environment.generated_utc?.slice(0, 10)}</p>
    </div>
  )
}

const ARCH: [string, string][] = [
  ['OpenStreetMap extract', 'real Bengaluru Urban buildings, roads, healthcare, amenities, leisure and land use'],
  ['Synthetic population generator', 'places synthetic agents in OSM-derived candidate homes and placeholder destinations; optional household structure from an experimental size PMF'],
  ['CEPOP file', 'binary population input consumed unchanged by every simulator backend'],
  ['Epidemic engine (V0–V6)', 'V0 CPU reference through V6 CUDA; results are checked by daily S/E/I/R checksum'],
  ['FastAPI + dashboard', 'serves recorded files read-only; separate /api/sim endpoints launch live runs'],
]
const LINKS: [string, string, string][] = [
  ['gis', 'GIS Explorer', 'Real OSM layers and synthetic locations on the map'],
  ['population', 'Population Explorer', 'Households, occupancy, destinations and assignment distances'],
  ['epidemic', 'Epidemic Analysis', 'S/E/I/R curves, attack rate, peaks and transmission sensitivity'],
  ['scenarios', 'Scenario Comparison', 'Legacy vs household, low/baseline/high, ten-seed V0 validation'],
  ['gpu', 'PAGP Performance Lab', 'V0–V6 architecture and recorded benchmarks'],
  ['studio', 'Simulation Studio', 'Launch live simulations and view agents'],
]

function Pill({ s, label }: { s: Async<unknown>; label: string }) {
  const color = s.loading ? C.slate : s.error ? C.coral : C.sage
  return <span className="inline-flex items-center gap-1.5 rounded-full border border-line bg-surface px-2.5 py-1 text-xs"><span className="h-2 w-2 rounded-full" style={{ background: color }} />{label}<span className="text-mute">{s.loading ? 'checking…' : s.error ? 'unavailable' : 'ok'}</span></span>
}

/** Live status of the API (these are probes of the running backend, not recorded results). */
function BackendStatus() {
  const health = useApi<{ status: string; bundle_exists: boolean }>('/api/health')
  const sim = useApi<{ backends: { id: string; label: string; available: boolean }[] }>('/api/sim/capabilities')
  const bk = sim.data?.backends ?? []
  return (
    <div className="flex flex-wrap items-center gap-2 text-xs">
      <Source kind="live">Live probe</Source>
      <Pill s={health} label="API" />
      {health.data && <Pill s={{ loading: false, error: health.data.bundle_exists ? undefined : 'missing' }} label="Data bundle" />}
      <Pill s={sim} label="Simulation API" />
      {bk.map((b) => <span key={b.id} className="inline-flex items-center gap-1.5 rounded-full border border-line bg-surface px-2.5 py-1"><span className="h-2 w-2 rounded-full" style={{ background: b.available ? C.sage : C.slate }} />{b.label}<span className="text-mute">{b.available ? 'available' : 'not available here'}</span></span>)}
    </div>
  )
}

const Row = ({ k, v }: { k: string; v: any }) => (<><dt className="text-mute">{k}</dt><dd className="text-right font-medium">{v}</dd></>)
