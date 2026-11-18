import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { Download, Map as MapIcon, Play, RefreshCw, Square, Trash2 } from 'lucide-react'
import SimulationViewer, { viewerBlocker } from '../components/SimulationViewer'
import { ApiError, checkForm, isTerminal, sim, toRequest, wallSeconds } from '../api/sim'
import type { FieldIssue, FormValues, Run, RunState, SeriesRow, SimCapabilities } from '../api/sim'
import { Badge, Card, ErrorState, Notice, PageHeader, PageSkeleton, Segmented, Skeleton, Stat, axis, axisLabel, grid, tooltipStyle } from '../components/ui'
import { compact, nf, pct, secs } from '../lib/format'
import { C, SEIR, SEIR_NAMES } from '../lib/theme'

const STATE_COLOR: Record<RunState, string> = { queued: C.slate, running: C.glacier, completed: C.sage, failed: C.coral, cancelled: C.amber }
const FIELDS: { key: keyof FormValues; label: string; step?: string; hint: string }[] = [
  { key: 'days', label: 'Days', hint: 'Simulated days (1–1000).' },
  { key: 'seed', label: 'Seed', hint: 'Same seed + same parameters gives an identical run.' },
  { key: 'initial_infected', label: 'Initial infected', hint: 'Agents infectious on day 0.' },
  { key: 'beta_home', label: 'β home', step: '0.01', hint: 'Per-day force of infection at the home location (CLI flag --beta-home). Experimental.' },
  { key: 'beta_work', label: 'β destination', step: '0.01', hint: 'Per-day force of infection at the work/destination location (CLI flag --beta-work). Experimental.' },
  { key: 'incubation_days', label: 'Incubation days', hint: 'Days in Exposed before becoming infectious.' },
  { key: 'infectious_days', label: 'Infectious days', hint: 'Days in Infectious before recovery.' },
]

const DEFAULT_INFECTED = 100 // sensible seed size; never inherits the population size

export default function SimulationStudio() {
  const [caps, setCaps] = useState<SimCapabilities | null>(null)
  const [err, setErr] = useState<string | null>(null)
  const load = useCallback((refresh = false) => {
    setErr(null)
    sim.capabilities(refresh).then(setCaps).catch((e: Error) => setErr(e.message))
  }, [])
  useEffect(() => { load() }, [load])

  return (
    <>
      <PageHeader subtitle="Configure and launch a real run of the C++ extpop_run executable on this machine, watch genuine day-by-day progress, then export the result or replay it on the Bengaluru map. Nothing is reimplemented in the browser or Python." />
      {err ? <ErrorState error={err} onRetry={() => load()} /> : !caps ? <PageSkeleton /> : <Studio caps={caps} refreshCaps={() => load(true)} />}
    </>
  )
}

function Studio({ caps, refreshCaps }: { caps: SimCapabilities; refreshCaps: () => void }) {
  const d = caps.defaults
  const firstOk = caps.backends.find((b) => b.available)?.id ?? caps.backends[0]?.id ?? ''
  const [dataset, setDataset] = useState(caps.datasets[0]?.id ?? '')
  const [backend, setBackend] = useState(firstOk)
  const [form, setForm] = useState<FormValues>({
    days: String(d.days), seed: String(d.seed), initial_infected: String(Math.min(DEFAULT_INFECTED, caps.datasets[0]?.agents ?? DEFAULT_INFECTED)), beta_home: String(d.beta_home),
    beta_work: String(d.beta_work), incubation_days: String(d.incubation_days), infectious_days: String(d.infectious_days),
  })
  const [serverIssues, setServerIssues] = useState<FieldIssue[]>([])
  const [warnings, setWarnings] = useState<FieldIssue[]>([])
  const [submitting, setSubmitting] = useState(false)
  const [msg, setMsg] = useState<string | null>(null)
  const [runs, setRuns] = useState<Run[]>([])
  const [sel, setSel] = useState<string | null>(null)
  const [snapshots, setSnapshots] = useState(false)
  const [viewing, setViewing] = useState<string | null>(null) // run id open in the Simulation Viewer

  const ds = caps.datasets.find((x) => x.id === dataset)
  const be = caps.backends.find((x) => x.id === backend)
  const snapOn = snapshots && !!be?.supports_snapshots
  const local = useMemo(() => checkForm(form, caps.limits, ds?.agents, snapOn ? caps.snapshot_max_days : undefined), [form, caps.limits, caps.snapshot_max_days, ds, snapOn])
  const fieldErr = (k: string) => local[k] ?? serverIssues.find((i) => i.field === k)?.message

  const refreshRuns = useCallback(() => sim.list().then((r) => setRuns(r.runs)).catch(() => { /* surfaced by selected-run polling */ }), [])
  useEffect(() => { refreshRuns() }, [refreshRuns])
  const anyActive = runs.some((r) => !isTerminal(r.state))
  useEffect(() => {
    if (!anyActive) return
    const t = setInterval(refreshRuns, 1000)
    return () => clearInterval(t)
  }, [anyActive, refreshRuns])

  const setField = (k: keyof FormValues, v: string) => { setForm({ ...form, [k]: v }); setServerIssues([]); setWarnings([]) }

  async function start() {
    setMsg(null)
    if (Object.keys(local).length || !ds || !be) return
    setSubmitting(true)
    try {
      const req = toRequest(dataset, backend, form, snapOn)
      const v = await sim.validate(req)
      setWarnings(v.warnings)
      if (!v.valid) { setServerIssues(v.errors); return }
      const run = await sim.start(req)
      setServerIssues([]); setSel(run.id); setRuns((rs) => [run, ...rs.filter((r) => r.id !== run.id)])
    } catch (e) {
      if (e instanceof ApiError) { setServerIssues(e.errors); setMsg(e.message) } else setMsg(String(e))
    } finally { setSubmitting(false) }
  }

  const selected = runs.find((r) => r.id === sel) ?? null
  const viewed = runs.find((r) => r.id === viewing) ?? null
  if (viewed) return <SimulationViewer key={viewed.id} run={viewed} onClose={() => setViewing(null)} />

  return (
    <div className="space-y-5">
      {caps.backends.every((b) => b.supports_snapshots === undefined) && <Notice>The API server appears to be an older build (it does not report snapshot support). Restart the backend from the current code to use snapshots.</Notice>}
      <Notice tone="info">
        <b>Runs here are live, not recorded.</b> Every run starts the real executable; its numbers belong to the configuration shown, and are separate from the recorded Kaggle/Overview results elsewhere in the app. Runs execute on <b>this host</b> ({caps.host.cpu || caps.host.machine}, {caps.host.cpu_count} CPUs). The synthetic population is not census data and all transmission rates are experimental.
        {caps.model_notes.length > 0 && <ul className="mt-1 list-disc pl-4">{caps.model_notes.map((n) => <li key={n}>{n}</li>)}</ul>}
      </Notice>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,380px)_minmax(0,1fr)]">
        <Card title="Configure run" sub={`${caps.max_concurrent_runs} run${caps.max_concurrent_runs === 1 ? '' : 's'} execute at once; further submissions wait in the queue`}
          right={<button onClick={refreshCaps} title="Re-probe backends" aria-label="Re-probe backends" className="rounded-md p-1.5 text-mute hover:bg-surface-3"><RefreshCw size={14} /></button>}>
          <div className="space-y-4">
            <label className="block text-xs font-medium text-ink-2">Population
              <select value={dataset} onChange={(e) => { setDataset(e.target.value); setServerIssues([]) }} className="mt-1 w-full rounded-lg border border-line bg-surface px-3 py-2 text-sm">
                {caps.datasets.map((x) => <option key={x.id} value={x.id}>{x.label}</option>)}
              </select>
              {caps.datasets.length === 0 && <span className="mt-1 block text-coral">No populations found on the server.</span>}
              {ds && <span className="mt-1 block font-mono text-[11px] font-normal text-mute">{ds.id} · {nf(ds.agents)} agents · {nf(ds.locations)} locations</span>}
              {fieldErr('dataset') && <span className="mt-1 block text-coral">{fieldErr('dataset')}</span>}
            </label>

            <div>
              <Segmented label="Backend" value={backend} onChange={setBackend} options={caps.backends.map((b) => ({ id: b.id, label: b.label + (b.available ? '' : ' (unavailable)') }))} />
              {be && <p className="mt-1.5 text-xs text-mute">{be.description}{!be.available && be.reason && <span className="block text-coral">Unavailable: {be.reason}</span>}
                {!be.available && be.hardware === 'gpu' && <span className="block text-mute">This machine has no usable CUDA executable/GPU, so this backend cannot run here. Recorded Kaggle T4 results for V5/V6 are available (read-only) in the <a className="text-teal-700 underline" href="#gpu/bench">PAGP Performance Lab</a>.</span>}
                {be.available && !be.progress_per_day && <span className="block">No per-day progress is reported by this backend; the chart appears when the run finishes.</span>}</p>}
              {fieldErr('backend') && <p className="mt-1 text-xs text-coral">{fieldErr('backend')}</p>}
            </div>

            <div className="grid grid-cols-2 gap-3">
              {FIELDS.map((f) => {
                const e = fieldErr(f.key)
                return (
                  <label key={f.key} className="block text-xs font-medium text-ink-2" title={f.hint}>{f.label}
                    <input inputMode="decimal" value={form[f.key]} onChange={(ev) => setField(f.key, ev.target.value)} aria-invalid={!!e}
                      className={`mt-1 w-full rounded-lg border bg-surface px-3 py-2 font-mono text-sm ${e ? 'border-coral' : 'border-line'}`} />
                    {e && <span className="mt-0.5 block font-normal text-coral">{e}</span>}
                  </label>
                )
              })}
            </div>

            <label className={`flex items-start gap-2.5 rounded-lg border border-line p-2.5 text-xs ${be?.supports_snapshots ? 'cursor-pointer' : 'opacity-60'}`} title="Stores every agent's state at the end of every day so the run can be replayed on the map.">
              <input type="checkbox" className="mt-0.5" checked={snapOn} disabled={!be?.supports_snapshots} onChange={(e) => setSnapshots(e.target.checked)} />
              <span><b className="text-ink">Record per-agent snapshots</b> for the Simulation Viewer
                <span className="block text-mute">{be?.supports_snapshots ? `About ${((ds?.agents ?? 0) * (Number(form.days) + 1) / 4 / 2 ** 20).toFixed(1)} MiB. Does not change results.` : 'Snapshots are supported by V0 only (the CESNAP writer is wired into the V0 reference loop).'}</span></span>
            </label>
            {!local.initial_infected && ds && Number(form.initial_infected) === ds.agents && <Notice>Every agent starts infected, so no one is left to infect. Use a much smaller seed (default {DEFAULT_INFECTED}).</Notice>}
            {warnings.map((w) => <Notice key={w.message}>{w.message}</Notice>)}
            {msg && <Notice>{msg}</Notice>}
            <button onClick={start} disabled={submitting || !be?.available || !ds || Object.keys(local).length > 0}
              className="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-teal-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-teal-600 disabled:cursor-not-allowed disabled:opacity-50">
              <Play size={15} /> {submitting ? 'Starting…' : 'Run simulation'}
            </button>
          </div>
        </Card>

        <div className="min-w-0 space-y-5">
          {selected ? <RunView key={selected.id} run={selected} onOpenViewer={() => setViewing(selected.id)} onChanged={refreshRuns} onRemoved={() => { setSel(null); refreshRuns() }} />
            : <Card><p className="py-10 text-center text-sm text-mute">Configure a run and press <b>Run simulation</b>, or pick a run from the history below.</p></Card>}
          <History runs={runs} sel={sel} onSelect={setSel} />
        </div>
      </div>
    </div>
  )
}

function RunView({ run: initial, onChanged, onRemoved, onOpenViewer }: { run: Run; onChanged: () => void; onRemoved: () => void; onOpenViewer: () => void }) {
  const [run, setRun] = useState(initial)
  const [rows, setRows] = useState<SeriesRow[]>([])
  const [log, setLog] = useState<string[] | null>(null)
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState<string | null>(null)
  const [now, setNow] = useState(Date.now())
  const lastDay = useRef(-1)
  const active = !isTerminal(run.state)

  // Poll run metadata + incremental series while the run is active; one final fetch when it ends.
  useEffect(() => {
    let stop = false
    const tick = async () => {
      try {
        const r = await sim.get(initial.id)
        if (stop) return
        setRun(r); setErr(null)
        if (r.state !== 'queued') {
          const s = await sim.series(initial.id, lastDay.current)
          if (stop) return
          if (s.rows.length) { lastDay.current = s.rows[s.rows.length - 1].day; setRows((p) => [...p, ...s.rows]) }
        }
        if (isTerminal(r.state)) { onChanged(); return }
        timer = setTimeout(tick, 1000)
      } catch (e) { if (!stop) { setErr((e as Error).message); timer = setTimeout(tick, 3000) } }
    }
    let timer = setTimeout(tick, 0)
    return () => { stop = true; clearTimeout(timer) }
  }, [initial.id, onChanged])

  useEffect(() => { if (!active) return; const t = setInterval(() => setNow(Date.now()), 500); return () => clearInterval(t) }, [active])
  useEffect(() => {
    if (run.state === 'failed' || run.state === 'cancelled') sim.log(run.id, 'stderr').then((l) => setLog(l.lines)).catch(() => setLog([]))
  }, [run.state, run.id])

  const act = async (fn: () => Promise<unknown>, after?: () => void) => {
    setBusy(true); setErr(null)
    try { await fn(); after?.() } catch (e) { setErr((e as Error).message) } finally { setBusy(false) }
  }
  const p = run.progress, res = run.result, N = run.dataset.agents
  const wall = wallSeconds(run.started_at, run.finished_at, now)

  return (
    <Card title={<span className="flex flex-wrap items-center gap-2">{run.label ?? `${run.backend.label} · ${run.dataset.id}`}<Badge color={STATE_COLOR[run.state]}>{run.state}</Badge></span>}
      sub={<span className="font-mono text-[11px]">{run.id} · {run.request.days} days · seed {run.request.seed}{run.backend.device ? ` · ${run.backend.device}` : ''}</span>}
      right={<div className="flex gap-1.5">
        {active && <button disabled={busy} onClick={() => act(() => sim.cancel(run.id))} className="inline-flex items-center gap-1.5 rounded-lg border border-line px-2.5 py-1.5 text-xs font-medium hover:bg-surface-3"><Square size={12} /> Cancel</button>}
        {run.state === 'completed' && run.snapshots?.requested && <button onClick={onOpenViewer} disabled={!!viewerBlocker(run)} title={viewerBlocker(run) ?? 'Replay this run on the Bengaluru map'} className="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-teal-600 disabled:opacity-50"><MapIcon size={12} /> Open viewer</button>}
        {run.state === 'completed' && <>
          <a href={sim.exportUrl(run.id, 'csv')} className="inline-flex items-center gap-1.5 rounded-lg border border-line px-2.5 py-1.5 text-xs font-medium hover:bg-surface-3"><Download size={12} /> CSV</a>
          <a href={sim.exportUrl(run.id, 'json')} className="inline-flex items-center gap-1.5 rounded-lg border border-line px-2.5 py-1.5 text-xs font-medium hover:bg-surface-3"><Download size={12} /> JSON</a></>}
        {!active && <button disabled={busy} onClick={() => act(() => sim.remove(run.id), onRemoved)} aria-label="Delete run" className="rounded-lg border border-line p-1.5 text-coral hover:bg-surface-3"><Trash2 size={13} /></button>}
      </div>}>
      <div className="space-y-4">
        <p role="status" className="sr-only" data-testid="run-status">{`Run ${run.id} is ${run.state}.`}</p>
        {err && <Notice>{err}</Notice>}
        {active && (
          <div>
            <div className="mb-1 flex justify-between text-xs text-ink-2">
              <span>{run.state === 'queued' ? 'Queued — waiting for a free slot' : p.supported && p.day != null ? `Day ${p.day} of ${p.total_days}` : 'Running — this backend reports no per-day progress'}</span>
              <span className="font-mono">{secs(wall)}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-surface-3" role="progressbar" aria-label="Simulation progress" aria-valuemin={0} aria-valuemax={100} aria-valuenow={p.fraction == null ? undefined : Math.round(p.fraction * 100)} aria-valuetext={p.fraction == null ? 'Progress not reported by this backend' : `Day ${p.day} of ${p.total_days}`}>
              <div className={`h-full rounded-full bg-teal-500 transition-all ${p.fraction == null ? 'w-full animate-pulse opacity-40' : ''}`} style={p.fraction == null ? undefined : { width: `${p.fraction * 100}%` }} />
            </div>
          </div>
        )}

        <RunConfig run={run} />
        {run.state === 'failed' && <Notice>{run.error?.message ?? 'The run failed.'}{run.exit_code != null && ` (exit code ${run.exit_code})`}</Notice>}
        {run.state === 'cancelled' && <Notice tone="info">This run was cancelled. No result files were kept.</Notice>}
        {log && log.length > 0 && <pre className="max-h-48 overflow-auto rounded-lg bg-nav p-3 text-[11px] leading-relaxed text-nav-ink">{log.join('\n')}</pre>}

        {(p.S != null && active) && (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {(['S', 'E', 'I', 'R'] as const).map((k) => <Stat key={k} label={SEIR_NAMES[k]} value={nf(p[k])} color={SEIR[k]} sub={pct(((p[k] ?? 0) / N) * 100, 2)} />)}
          </div>
        )}
        {res && (
          <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
            <Stat label="Attack rate" value={pct(res.attack_rate_pct, 2)} color={C.coral} />
            <Stat label="Peak infectious" value={nf(res.peak_infectious)} sub={`day ${res.peak_day}`} color={C.coral} />
            <Stat label="Peak daily incidence" value={nf(res.peak_daily_incidence)} sub={`day ${res.peak_incidence_day}`} color={C.amber} />
            <Stat label="Engine runtime" value={secs(res.runtime_seconds)} sub={wall != null ? `wall ${secs(wall)}` : undefined} color={C.teal} hint="Time measured inside the executable, versus wall-clock time including process start and file I/O." />
          </div>
        )}
        {run.state === 'completed' && rows.length === 0 && <Skeleton className="h-72" />}
        {rows.length > 0 && (
          <div className="h-72">
            <ResponsiveContainer>
              <LineChart data={rows} margin={{ top: 8, right: 12, bottom: 8, left: 0 }}>
                <CartesianGrid {...grid} vertical={false} />
                <XAxis dataKey="day" {...axis} label={axisLabel('day')} />
                <YAxis {...axis} tickFormatter={compact} width={48} />
                <Tooltip {...tooltipStyle} formatter={(v, n) => [nf(Number(v)), SEIR_NAMES[n as keyof typeof SEIR_NAMES] ?? String(n)]} labelFormatter={(l) => `Day ${l}`} />
                {(['S', 'E', 'I', 'R'] as const).map((k) => <Line key={k} dataKey={k} name={k} stroke={SEIR[k]} strokeWidth={2} dot={false} isAnimationActive={false} />)}
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
        {run.state === 'completed' && !run.snapshots?.requested && <p className="text-[11px] text-mute">This run did not record snapshots, so it cannot be replayed on the map. Start a new V0 run with “Record per-agent snapshots” enabled.</p>}
        {res?.daily_checksum && <p className="break-all font-mono text-[11px] text-mute">daily checksum {res.daily_checksum}</p>}
      </div>
    </Card>
  )
}

function History({ runs, sel, onSelect }: { runs: Run[]; sel: string | null; onSelect: (id: string) => void }) {
  return (
    <Card title="Run history" sub="Runs persist on the server until deleted">
      {runs.length === 0 ? <p className="py-4 text-sm text-mute">No runs yet.</p> : (
        <ul className="divide-y divide-line">
          {runs.map((r) => (
            <li key={r.id}>
              <button onClick={() => onSelect(r.id)} aria-current={r.id === sel} className={`flex w-full flex-wrap items-center gap-x-3 gap-y-1 px-2 py-2 text-left text-xs transition hover:bg-surface-3 ${r.id === sel ? 'bg-surface-2' : ''}`}>
                <Badge color={STATE_COLOR[r.state]}>{r.state}</Badge>
                {r.snapshots?.available && <span className="rounded bg-teal-50 px-1.5 py-0.5 text-[10px] font-semibold text-teal-700" title="Per-agent snapshots available: open in the viewer">MAP</span>}
                <span className="font-medium">{r.backend.label}</span>
                <span className="font-mono text-[11px]" title={r.dataset.label}>{r.dataset.id}</span>
                <span className="text-mute">{compact(r.dataset.agents)} agents</span>
                <span className="text-mute">{r.request.days}d · seed {r.request.seed}</span>
                {r.result && <span className="text-mute">attack {pct(r.result.attack_rate_pct, 1)}</span>}
                <span className="ml-auto font-mono text-mute">{new Date(r.created_at).toLocaleTimeString()}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </Card>
  )
}

function RunConfig({ run }: { run: Run }) {
  const q = run.request
  const items: [string, string][] = [
    ['Dataset ID', run.dataset.id], ['Dataset', run.dataset.label], ['Population', `${nf(run.dataset.agents)} agents`],
    ['Locations', nf(run.dataset.locations)], ['Backend', `${run.backend.label}${run.backend.device ? ` (${run.backend.device})` : ''}`],
    ['Days', String(q.days)], ['Seed', String(q.seed)],
    ['Initial infected', `${nf(q.initial_infected)} (${pct((q.initial_infected / run.dataset.agents) * 100, 3)})`],
    ['β home', String(q.beta_home)], ['β destination', String(q.beta_work)],
    ['Incubation', `${q.incubation_days} d`], ['Infectious', `${q.infectious_days} d`],
  ]
  return (
    <section aria-label="Run configuration" className="rounded-lg border border-line bg-surface-2 p-3">
      <h3 className="mb-2 text-[11px] font-semibold uppercase tracking-[0.08em] text-mute">Run configuration</h3>
      <dl className="grid grid-cols-2 gap-x-4 gap-y-2 sm:grid-cols-3 lg:grid-cols-4">
        {items.map(([k, v]) => <div key={k} className="min-w-0"><dt className="text-[11px] text-mute">{k}</dt><dd className="break-words font-mono text-xs font-medium">{v}</dd></div>)}
      </dl>
    </section>
  )
}
