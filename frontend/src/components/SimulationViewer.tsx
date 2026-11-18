import { memo, useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from 'react'
import L from 'leaflet'
import { Area, AreaChart, CartesianGrid, Line, LineChart, ReferenceLine, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { AlertTriangle, ArrowLeft, CheckCircle2, ChevronDown, ChevronUp, Info, Loader2, Pause, Play, RotateCcw, SkipBack, SkipForward } from 'lucide-react'
import { sim } from '../api/sim'
import type { Run, SeriesRow } from '../api/sim'
import { fetchFrame, fetchHomePositions, fetchSnapshotMeta, SnapshotError } from '../api/snapshots'
import type { SnapshotMeta } from '../api/snapshots'
import { getJSON } from '../api/client'
import { AgentLayer } from '../lib/agentLayer'
import type { HoverInfo, LayerStatus, ViewMode } from '../lib/agentLayer'
import { compact, nf } from '../lib/format'
import { SEIR, SEIR_NAMES } from '../lib/theme'
import { deriveStats, FrameStore, INDIVIDUAL_ZOOM, initialPlay, playReducer, Positions, SPEEDS, verifyAgainstSeries } from '../lib/viewerCore'
import type { PlayAction, PlayState } from '../lib/viewerCore'

const KEYS = ['S', 'E', 'I', 'R'] as const
const DARK_TILES = 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'

interface Loaded { meta: SnapshotMeta; pos: Positions; rows: SeriesRow[]; store: FrameStore }

/** Why a run cannot be viewed, decided from run metadata alone (no request needed). */
export function viewerBlocker(run: Run): string | null {
  if (run.state === 'queued' || run.state === 'running') return 'This run has not finished. The viewer opens once it completes and its snapshots are validated.'
  if (run.state === 'failed') return 'This run failed, so no validated snapshots exist for it.'
  if (run.state === 'cancelled') return 'This run was cancelled, so no snapshots were kept.'
  if (run.backend.id !== 'v0') return `Snapshots are currently supported by V0 only; this run used ${run.backend.label}.`
  if (!run.snapshots?.requested) return 'This run did not record snapshots. Start a new V0 run with "Record per-agent snapshots" enabled.'
  if (!run.snapshots.available) return 'Snapshots were requested but are not available (they failed validation or were removed).'
  return null
}

export default function SimulationViewer({ run, onClose }: { run: Run; onClose: () => void }) {
  const blocker = viewerBlocker(run)
  const [attempt, setAttempt] = useState(0)
  const [data, setData] = useState<Loaded | null>(null)
  const [err, setErr] = useState<{ kind: string; message: string } | null>(null)

  useEffect(() => {
    if (blocker) return
    let cancelled = false
    setData(null); setErr(null)
    ;(async () => {
      try {
        const meta = await fetchSnapshotMeta(run.id)
        const n = meta.info.n_agents, F = meta.info.n_frames
        if (n !== run.dataset.agents) throw new SnapshotError('invalid', `Snapshot has ${nf(n)} agents but the run's population has ${nf(run.dataset.agents)}.`)
        const [buf, series] = await Promise.all([fetchHomePositions(run.id, n), sim.series(run.id, -1)])
        if (series.rows.length !== F) throw new SnapshotError('invalid', `Snapshot has ${F} frames but the daily CSV has ${series.rows.length} rows.`)
        const pos = new Positions(buf, n)
        const store = new FrameStore(n, F, (d) => fetchFrame(run.id, d, n))
        await store.ensure(0)
        if (cancelled) return
        setData({ meta, pos, rows: series.rows, store })
        void store.preload(6, () => cancelled)
      } catch (e) {
        if (cancelled) return
        setErr(e instanceof SnapshotError ? { kind: e.kind, message: e.message } : { kind: 'invalid', message: (e as Error).message })
      }
    })()
    return () => { cancelled = true }
  }, [run.id, run.dataset.agents, blocker, attempt])

  return (
    <section aria-label="Simulation viewer" data-testid="viewer" className="overflow-hidden rounded-2xl border border-nav-line bg-nav text-nav-ink shadow-xl">
      {blocker ? <Shell run={run} onClose={onClose}><Message tone="info" title="Viewer unavailable for this run">{blocker}</Message></Shell>
        : err ? <Shell run={run} onClose={onClose}><Message tone="error" title={ERR_TITLE[err.kind] ?? 'Could not load snapshots'} onRetry={err.kind === 'unreachable' || err.kind === 'http' || err.kind === 'invalid' ? () => setAttempt((a) => a + 1) : undefined}>{err.message}</Message></Shell>
        : !data ? <Shell run={run} onClose={onClose}><div className="flex h-72 items-center justify-center gap-2 text-sm text-nav-mute" role="status"><Loader2 className="animate-spin" size={16} /> Loading validated snapshot, home positions and day 0…</div></Shell>
        : <Viewer key={run.id + ':' + attempt} run={run} data={data} onClose={onClose} />}
    </section>
  )
}

const ERR_TITLE: Record<string, string> = {
  unreachable: 'Backend unreachable', not_requested: 'No snapshots recorded', not_ready: 'Run not finished', unavailable: 'Snapshots unavailable', invalid: 'Snapshot data failed a consistency check', http: 'Server error',
}

function Shell({ run, onClose, children }: { run: Run; onClose: () => void; children: React.ReactNode }) {
  return (
    <>
      <Header run={run} onClose={onClose} />
      <div className="p-4">{children}</div>
    </>
  )
}

function Header({ run, onClose, right }: { run: Run; onClose: () => void; right?: React.ReactNode }) {
  return (
    <header className="flex flex-wrap items-center gap-x-3 gap-y-2 border-b border-nav-line px-4 py-2.5">
      <button onClick={onClose} className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-medium text-nav-mute hover:bg-nav-3 hover:text-nav-ink"><ArrowLeft size={14} /> Studio</button>
      <h2 className="text-sm font-semibold tracking-tight">Simulation Viewer</h2>
      <span className="rounded-full border border-teal-500/40 bg-teal-500/10 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-teal-400" title="This is the run you launched in the Studio, replayed from its own stored per-agent snapshots. It is not a recorded Kaggle result.">Your live run · replay</span>
      <span className="font-mono text-[11px] text-nav-mute">{run.id} · {run.backend.label} · {run.dataset.id} · seed {run.request.seed}</span>
      <div className="ml-auto flex items-center gap-2">{right}</div>
    </header>
  )
}

function Message({ tone, title, children, onRetry }: { tone: 'info' | 'error'; title: string; children: React.ReactNode; onRetry?: () => void }) {
  return (
    <div role={tone === 'error' ? 'alert' : 'status'} className="flex gap-3 rounded-xl border border-nav-line bg-nav-2 p-4">
      {tone === 'error' ? <AlertTriangle className="mt-0.5 shrink-0 text-coral" size={18} /> : <Info className="mt-0.5 shrink-0 text-glacier" size={18} />}
      <div className="min-w-0 text-sm">
        <div className="font-semibold">{title}</div>
        <p className="mt-1 text-nav-mute">{children}</p>
        {onRetry && <button onClick={onRetry} className="mt-3 rounded-md border border-nav-line px-3 py-1.5 text-xs font-medium hover:bg-nav-3">Retry</button>}
      </div>
    </div>
  )
}

/* ───────────────────────────── main viewer ───────────────────────────── */

function Viewer({ run, data, onClose }: { run: Run; data: Loaded; onClose: () => void }) {
  const { meta, pos, rows, store } = data
  const last = meta.info.n_frames - 1, n = meta.info.n_agents
  useSyncExternalStore(useCallback((f) => store.subscribe(f), [store]), () => store.version)

  // playback: the clock lives in a ref and React state changes only when the selected day / flags change
  const playRef = useRef<PlayState>(initialPlay(last))
  const [play, setPlay] = useState<PlayState>(playRef.current)
  const apply = useCallback((a: PlayAction) => {
    const p = playRef.current, nx = playReducer(p, a)
    playRef.current = nx
    if (a.type !== 'tick' || nx.day !== p.day || nx.playing !== p.playing || nx.buffering !== p.buffering) setPlay(nx)
  }, [])
  useEffect(() => {
    if (!play.playing) return
    let id = 0, prev = performance.now()
    const loop = (t: number) => { apply({ type: 'tick', dtMs: t - prev, ready: (d) => store.ready(d) }); prev = t; id = requestAnimationFrame(loop) }
    id = requestAnimationFrame(loop)
    return () => cancelAnimationFrame(id)
  }, [play.playing, apply, store])

  // the day every panel shows: only advances once that day's real frame (and the previous day's counts) are in memory
  const [shown, setShown] = useState(0)
  const selectedReady = store.ready(play.day)
  useEffect(() => { if (selectedReady) setShown(play.day) }, [play.day, selectedReady, store.version])
  useEffect(() => { if (!store.ready(play.day)) store.ensure(play.day).catch(() => { /* surfaced through store.errors */ }) }, [play.day, store, store.version])
  const failed = [...store.errors.entries()]
  useEffect(() => { if (play.buffering && store.errors.has(play.day + 1)) apply({ type: 'pause' }) }, [play.buffering, play.day, store.version, store, apply])

  const frame = store.frame(shown)
  const counts = store.counts(shown)
  const prevCounts = shown > 0 ? store.counts(shown - 1) ?? null : null
  const stats = counts ? deriveStats(n, counts, prevCounts) : null
  const csv = rows[shown]
  const mismatches = useMemo(() => (stats ? verifyAgainstSeries(stats.counts, stats.incidence, csv, shown) : []), [stats, csv, shown])

  const [mode, setMode] = useState<ViewMode>('composition')
  const [basemap, setBasemap] = useState(false)
  const [info, setInfo] = useState(true)
  const [status, setStatus] = useState<LayerStatus | null>(null)
  const [chartKind, setChartKind] = useState<'seir' | 'active' | 'incidence'>('seir')

  const onKey = (e: React.KeyboardEvent) => {
    if ((e.target as HTMLElement).tagName === 'INPUT' && (e.target as HTMLInputElement).type !== 'range') return
    if (e.key === ' ' && (e.target as HTMLElement).tagName !== 'BUTTON') { e.preventDefault(); apply({ type: play.playing ? 'pause' : 'play' }) }
    else if (e.key === 'ArrowRight' && (e.target as HTMLElement).tagName !== 'INPUT') apply({ type: 'seek', day: playRef.current.day + 1 })
    else if (e.key === 'ArrowLeft' && (e.target as HTMLElement).tagName !== 'INPUT') apply({ type: 'seek', day: playRef.current.day - 1 })
  }
  const loading = !selectedReady
  const dayLabel = `Day ${shown} / ${last}`

  return (
    <div onKeyDown={onKey} tabIndex={-1} className="outline-none">
      <Header run={run} onClose={onClose} right={
        <>
          <span className="rounded-md bg-nav-3 px-2 py-1 font-mono text-[11px] text-nav-mute" title="Frames fetched from the server so far">{store.loaded}/{meta.info.n_frames} frames cached</span>
          <button onClick={() => setInfo(!info)} aria-expanded={info} className="inline-flex items-center gap-1 rounded-md border border-nav-line px-2.5 py-1 text-xs font-medium hover:bg-nav-3">
            <Info size={13} /> Details {info ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
          </button>
        </>} />

      {/* S/E/I/R statistics strip: always the shown day */}
      <div data-testid="stats" data-day={shown} className="grid grid-cols-2 gap-px border-b border-nav-line bg-nav-line sm:grid-cols-3 lg:grid-cols-6">
        {KEYS.map((k, i) => (
          <StatTile key={k} label={SEIR_NAMES[k]} id={k} color={SEIR[k]} value={stats ? nf(stats.counts[i]) : '—'} sub={stats ? `${stats.pct[i].toFixed(2)}% of ${compact(n)}` : ''} frac={stats ? stats.pct[i] / 100 : 0} />
        ))}
        <StatTile label="Attack rate" id="attack" color="#e0735e" value={stats ? `${stats.attackRatePct.toFixed(2)}%` : '—'} sub="ever infected: 1 − S/N" frac={stats ? stats.attackRatePct / 100 : 0} />
        <StatTile label="Daily incidence" id="incidence" color="#d9982a" value={stats ? nf(stats.incidence) : '—'} sub={shown === 0 ? 'day 0 = seeded state' : 'new exposures (S drop)'} frac={0} />
      </div>

      <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_340px]">
        <div className="min-w-0">
          <div className="relative isolate">
          <div className="relative h-[58vh] min-h-[380px] lg:h-[max(440px,calc(100vh-430px))]">
            <MapPane pos={pos} frame={frame} mode={mode} basemap={basemap} onStatus={setStatus} />
            {/* top-left: view controls */}
            <div className="pointer-events-none absolute left-3 top-3 z-[500] flex flex-col gap-2">
              <div className="pointer-events-auto rounded-lg border border-nav-line bg-nav/90 p-1 text-[11px] shadow-lg backdrop-blur" role="group" aria-label="Map view">
                {([['composition', 'Composition'], ['infection', 'Active infection']] as const).map(([id, l]) => (
                  <button key={id} onClick={() => setMode(id)} aria-pressed={mode === id} className={`rounded-md px-2.5 py-1 font-medium ${mode === id ? 'bg-teal-500 text-white' : 'text-nav-mute hover:text-nav-ink'}`}>{l}</button>
                ))}
              </div>
              <p className="pointer-events-none hidden max-w-[210px] sm:block rounded-lg border border-nav-line bg-nav/90 px-2.5 py-1.5 text-[11px] leading-snug text-nav-mute shadow-lg backdrop-blur">{mode === 'composition' ? 'Composition: each cell’s colour is the exact mix of S/E/I/R agents living there.' : 'Active infection: cells are shaded by the share of agents Exposed or Infectious (blue-grey → red).'}</p>
              <label className="pointer-events-auto flex w-fit items-center gap-2 rounded-lg border border-nav-line bg-nav/90 px-2.5 py-1.5 text-[11px] text-nav-mute shadow-lg backdrop-blur">
                <input type="checkbox" checked={basemap} onChange={(e) => setBasemap(e.target.checked)} /> Street basemap (online)
              </label>
            </div>
            {/* bottom-left: legend + scale mode */}
            <Legend mode={mode} status={status} />
            {loading && <div role="status" className="absolute left-1/2 top-3 z-[600] -translate-x-1/2 rounded-full border border-nav-line bg-nav/95 px-3 py-1 text-xs shadow-lg"><Loader2 className="mr-1.5 inline animate-spin" size={12} />Loading day {play.day}…</div>}
          </div>
          </div>
      {failed.length > 0 && (
        <div role="alert" className="flex flex-wrap items-center gap-3 border-t border-nav-line bg-coral/10 px-4 py-2 text-xs text-coral">
          <AlertTriangle size={13} /> {failed.length === 1 ? `Day ${failed[0][0]} could not be loaded` : `${failed.length} frames could not be loaded`}: {failed[0][1]}
          <button onClick={() => failed.forEach(([d]) => store.ensure(d).catch(() => undefined))} className="rounded-md border border-coral/40 px-2 py-0.5 font-medium hover:bg-coral/10">Retry</button>
        </div>
      )}

      {/* playback toolbar */}
      <div className="flex flex-wrap items-center gap-x-4 gap-y-2 border-t border-nav-line bg-nav-2 px-4 py-2.5" role="toolbar" aria-label="Playback">
        <div className="flex items-center gap-1.5">
          <button onClick={() => apply({ type: 'reset' })} aria-label="Reset to day 0" title="Reset to day 0" className="rounded-lg border border-nav-line p-2 hover:bg-nav-3"><RotateCcw size={15} /></button>
          <button onClick={() => apply({ type: 'seek', day: playRef.current.day - 1 })} disabled={play.day <= 0} aria-label="Previous day" title="Previous day (←)" className="rounded-lg border border-nav-line p-2 hover:bg-nav-3 disabled:opacity-40"><SkipBack size={15} /></button>
          <button onClick={() => apply({ type: play.playing ? 'pause' : 'play' })} aria-label={play.playing ? 'Pause' : play.day >= last ? 'Replay from day 0' : 'Play'} className="inline-flex w-24 items-center justify-center gap-1.5 rounded-lg bg-teal-500 px-3 py-2 text-sm font-semibold text-white hover:bg-teal-600">
            {play.playing ? <><Pause size={15} /> Pause</> : <><Play size={15} /> {play.day >= last ? 'Replay' : 'Play'}</>}
          </button>
          <button onClick={() => apply({ type: 'seek', day: playRef.current.day + 1 })} disabled={play.day >= last} aria-label="Next day" title="Next day (→)" className="rounded-lg border border-nav-line p-2 hover:bg-nav-3 disabled:opacity-40"><SkipForward size={15} /></button>
        </div>
        <div className="flex items-center gap-0.5 rounded-lg border border-nav-line p-0.5" role="group" aria-label="Playback speed">
          {SPEEDS.map((s) => <button key={s} onClick={() => apply({ type: 'speed', speed: s })} aria-pressed={play.speed === s} className={`rounded-md px-2 py-1 font-mono text-xs ${play.speed === s ? 'bg-nav-3 text-nav-ink' : 'text-nav-mute hover:text-nav-ink'}`}>{s}×</button>)}
        </div>
        <input type="range" min={0} max={last} step={1} value={play.day} onChange={(e) => apply({ type: 'seek', day: Number(e.target.value) })} aria-label="Day timeline"
          aria-valuetext={`Day ${play.day} of ${last}`} className="h-2 min-w-[160px] flex-1 cursor-pointer accent-teal-500" />
        <div className="w-28 text-right font-mono text-sm tabular-nums" data-testid="day-label" aria-live="off">{dayLabel}{play.buffering && <span className="ml-1 text-amber">…</span>}</div>
      </div>

        </div>
        <div className="relative border-t border-nav-line bg-nav lg:border-l lg:border-t-0">
          <div className="lg:absolute lg:inset-0 lg:overflow-y-auto">
      {/* synchronised trajectory */}
      <div className="px-3 pb-3 pt-3">
        <div className="mb-1 flex flex-wrap items-center justify-between gap-1 text-xs">
          <span className="font-semibold">Epidemic trajectory <span className="block font-normal text-nav-mute">full run, daily CSV · marker = day {shown}</span></span>
          <div className="flex gap-0.5 rounded-lg border border-nav-line p-0.5" role="group" aria-label="Chart series">
            {([['seir', 'S/E/I/R'], ['active', 'E/I/R'], ['incidence', 'Incidence']] as const).map(([id, l]) => <button key={id} onClick={() => setChartKind(id)} aria-pressed={chartKind === id} className={`rounded-md px-2 py-0.5 ${chartKind === id ? 'bg-nav-3 text-nav-ink' : 'text-nav-mute hover:text-nav-ink'}`}>{l}</button>)}
          </div>
        </div>
        <Trajectory rows={rows} day={shown} kind={chartKind} onSeek={(d) => apply({ type: 'seek', day: d })} />
      </div>

        {info && (
          <aside aria-label="Run information" className="border-t border-nav-line p-3 text-xs leading-relaxed">
            <h3 className="mb-2 text-[11px] font-semibold uppercase tracking-[0.08em] text-nav-mute">About this view</h3>
            <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1">
              <dt className="text-nav-mute">Agents</dt><dd className="font-mono">{nf(n)}</dd>
              <dt className="text-nav-mute">Frames</dt><dd className="font-mono">{meta.info.n_frames} (days 0–{last})</dd>
              <dt className="text-nav-mute">Backend</dt><dd className="font-mono">{meta.info.backend ?? 'V0'}</dd>
              <dt className="text-nav-mute">Seed</dt><dd className="font-mono">{meta.info.seed}</dd>
              <dt className="text-nav-mute">Snapshot</dt><dd className="font-mono">{(meta.info.file_bytes / 2 ** 20).toFixed(2)} MiB</dd>
              <dt className="text-nav-mute">Dataset CRC</dt><dd className="font-mono">{meta.info.dataset_payload_crc32}</dd>
              <dt className="text-nav-mute">Render</dt><dd className="font-mono" data-testid="render-mode">{status ? (status.mode === 'grid' ? `grid · ${nf(status.cells)} cells` : `agents · ${nf(status.visibleAgents)} in view`) : '—'}</dd>
              <dt className="text-nav-mute">Last draw</dt><dd className="font-mono">{status ? `${status.drawMs.toFixed(1)} ms` : '—'}</dd>
              <dt className="text-nav-mute">Frame cache</dt><dd className="font-mono">{(store.residentBytes / 2 ** 20).toFixed(1)} MiB</dd>
            </dl>
            <ul className="mt-3 list-disc space-y-1.5 pl-4 text-nav-mute">
              <li>Frame <i>d</i> is every agent&apos;s real V0 state at the end of day <i>d</i>. Playback steps through stored frames only.</li>
              <li>Below zoom {INDIVIDUAL_ZOOM} agents are aggregated into grid cells; at zoom {INDIVIDUAL_ZOOM}+ each agent is drawn. Agents sharing a home overlap; infectious agents are drawn on top.</li>
              <li><b className="text-nav-ink">Composition</b> mixes the S/E/I/R colours in exact proportion. <b className="text-nav-ink">Active infection</b> shades cells by the share of Exposed + Infectious. Opacity encodes agents per cell.</li>
              <li>Keys: <kbd>Space</kbd> play/pause, <kbd>←</kbd>/<kbd>→</kbd> step one day.</li>
            </ul>
            <div className={`mt-3 flex items-start gap-1.5 rounded-md px-2 py-1.5 ${mismatches.length ? 'bg-coral/15 text-coral' : 'bg-sage/15 text-sage'}`} data-testid="verify">
              {mismatches.length ? <AlertTriangle size={13} className="mt-0.5 shrink-0" /> : <CheckCircle2 size={13} className="mt-0.5 shrink-0" />}
              <span>{mismatches.length ? `Day ${shown} differs from the daily CSV: ${mismatches.join('; ')}` : `Day ${shown}: frame counts and incidence match the daily CSV exactly.`}</span>
            </div>
          </aside>
        )}
          </div>
        </div>
      </div>

      {/* persistent scientific note (not collapsible) */}
      <div role="note" data-testid="sci-note" className="border-t border-nav-line bg-nav-2 px-4 py-2.5 text-[11px] leading-relaxed text-nav-mute">
        <b className="text-nav-ink">Read this map carefully.</b> Agents are drawn at their <b>fixed home locations</b>; the model does <b>not</b> simulate physical movement. A state change does <b>not</b> show where transmission occurred
        (it may have happened at the destination), and no transmission links are recorded. Snapshots are currently supported by <b>V0 only</b>. The population is <b>synthetic</b>, not census data, and rates are experimental.
      </div>
    </div>
  )
}

function StatTile({ id, label, value, sub, color, frac }: { id: string; label: string; value: string; sub: string; color: string; frac: number }) {
  return (
    <div className="bg-nav-2 px-4 py-3" data-testid={`stat-${id}`}>
      <div className="flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-[0.08em] text-nav-mute"><span className="h-2 w-2 rounded-full" style={{ background: color }} />{label}</div>
      <div className="mt-1 font-mono text-[22px] font-semibold leading-none tabular-nums" data-testid={`val-${id}`}>{value}</div>
      <div className="mt-1.5 truncate text-[11px] text-nav-mute">{sub}</div>
      <div className="mt-2 h-[3px] overflow-hidden rounded-full bg-nav-3"><div className="h-full rounded-full transition-[width] duration-200" style={{ width: `${Math.min(100, Math.max(0, frac * 100))}%`, background: color }} /></div>
    </div>
  )
}

function Legend({ mode, status }: { mode: ViewMode; status: LayerStatus | null }) {
  return (
    <div className="pointer-events-none absolute bottom-3 left-3 z-[500] rounded-lg border border-nav-line bg-nav/90 px-3 py-2 text-[11px] shadow-lg backdrop-blur" aria-label="Legend">
      {mode === 'composition' || status?.mode === 'individual' ? (
        <ul className="space-y-1">{KEYS.map((k) => <li key={k} className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full" style={{ background: SEIR[k] }} />{SEIR_NAMES[k]}</li>)}</ul>
      ) : (
        <div className="w-40"><div className="mb-1">Share Exposed + Infectious</div>
          <div className="h-2 rounded-full" style={{ background: 'linear-gradient(90deg,rgb(58,84,110),rgb(217,152,42),rgb(224,80,60))' }} />
          <div className="mt-0.5 flex justify-between font-mono text-nav-mute"><span>0%</span><span>50%</span><span>100%</span></div></div>
      )}
      <div className="mt-1.5 border-t border-nav-line pt-1.5 text-nav-mute">{status ? (status.mode === 'grid' ? 'Grid cells · opacity = agents per cell' : 'Individual agents at home locations') : ''}</div>
    </div>
  )
}

const Trajectory = memo(function Trajectory({ rows, day, kind, onSeek }: { rows: SeriesRow[]; day: number; kind: 'seir' | 'active' | 'incidence'; onSeek: (d: number) => void }) {
  const tick = { fill: '#8da0b1', fontSize: 11 }
  const handle = (s: unknown) => { const l = (s as { activeLabel?: string | number } | null)?.activeLabel; if (l != null && Number.isFinite(Number(l))) onSeek(Number(l)) }
  const tip = { contentStyle: { background: '#1f2b38', border: '1px solid #2a3745', borderRadius: 8, fontSize: 12 }, labelStyle: { color: '#e8eef3' }, itemStyle: { padding: 0 } }
  return (
    <div className="h-48" data-testid="trajectory" data-day={day}>
      <ResponsiveContainer>
        {kind !== 'incidence' ? (
          <LineChart data={rows} margin={{ top: 6, right: 10, bottom: 0, left: 0 }} onClick={handle}>
            <CartesianGrid stroke="#2a3745" strokeDasharray="3 4" vertical={false} />
            <XAxis dataKey="day" tick={tick} tickLine={false} axisLine={{ stroke: '#2a3745' }} />
            <YAxis tick={tick} tickLine={false} axisLine={false} tickFormatter={compact} width={44} />
            <Tooltip {...tip} formatter={(v, nm) => [nf(Number(v)), SEIR_NAMES[nm as keyof typeof SEIR_NAMES] ?? String(nm)]} labelFormatter={(l) => `Day ${l}`} />
            {KEYS.filter((k) => kind === 'seir' || k !== 'S').map((k) => <Line key={k} dataKey={k} stroke={SEIR[k]} strokeWidth={1.8} dot={false} isAnimationActive={false} />)}
            <ReferenceLine x={day} stroke="#e8eef3" strokeWidth={1.5} ifOverflow="visible" />
          </LineChart>
        ) : (
          <AreaChart data={rows} margin={{ top: 6, right: 10, bottom: 0, left: 0 }} onClick={handle}>
            <CartesianGrid stroke="#2a3745" strokeDasharray="3 4" vertical={false} />
            <XAxis dataKey="day" tick={tick} tickLine={false} axisLine={{ stroke: '#2a3745' }} />
            <YAxis tick={tick} tickLine={false} axisLine={false} tickFormatter={compact} width={44} />
            <Tooltip {...tip} formatter={(v) => [nf(Number(v)), 'New exposures']} labelFormatter={(l) => `Day ${l}`} />
            <Area dataKey="incidence" stroke="#d9982a" fill="#d9982a" fillOpacity={0.25} strokeWidth={1.8} isAnimationActive={false} />
            <ReferenceLine x={day} stroke="#e8eef3" strokeWidth={1.5} ifOverflow="visible" />
          </AreaChart>
        )}
      </ResponsiveContainer>
    </div>
  )
})

/* ───────────────────────────── map ───────────────────────────── */

function MapPane({ pos, frame, mode, basemap, onStatus }: { pos: Positions; frame: Uint8Array | undefined; mode: ViewMode; basemap: boolean; onStatus: (s: LayerStatus) => void }) {
  const el = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | undefined>(undefined)
  const layerRef = useRef<AgentLayer | undefined>(undefined)
  const tileRef = useRef<L.TileLayer | undefined>(undefined)
  const [tip, setTip] = useState<{ x: number; y: number; info: HoverInfo } | null>(null)
  const statusAt = useRef(0)
  const lastMode = useRef('')

  useEffect(() => {
    const map = L.map(el.current!, { preferCanvas: true, zoomControl: false, minZoom: 9, maxZoom: 19, zoomSnap: 0.5, attributionControl: false })
    L.control.zoom({ position: 'bottomright' }).addTo(map)
    const [s, w, nn, e] = pos.bounds
    map.fitBounds([[s, w], [nn, e]], { padding: [24, 24] })
    map.createPane('p-bound').style.zIndex = '405'
    map.createPane('p-agents').style.zIndex = '430'
    map.getPane('p-bound')!.style.pointerEvents = 'none'
    getJSON<any>('/api/geo/boundary').then((g) => {
      if (mapRef.current === map) L.geoJSON(g, { pane: 'p-bound', interactive: false, style: { color: '#5fb8b0', weight: 1.5, fillColor: '#2f9a93', fillOpacity: 0.05, dashArray: '6 4' } }).addTo(map)
    }).catch(() => { /* boundary is decoration; the agents still render */ })
    const layer = new AgentLayer('p-agents')
    layer.onStatus = (st) => { // throttle React updates; still report every mode change
      const now = performance.now()
      if (st.mode !== lastMode.current || now - statusAt.current > 300) { lastMode.current = st.mode; statusAt.current = now; onStatus(st) }
    }
    layer.setData(pos)
    layer.addTo(map)
    layerRef.current = layer; mapRef.current = map
    let raf = 0
    map.on('mousemove', (ev: L.LeafletMouseEvent) => {
      if (raf) return
      raf = requestAnimationFrame(() => { raf = 0; const h = layer.hover(ev.containerPoint); setTip(h ? { x: ev.containerPoint.x, y: ev.containerPoint.y, info: h } : null) })
    })
    map.on('mouseout movestart zoomstart', () => setTip(null))
    el.current!.dataset.ready = '1'
    ;(el.current as any).__map = map; (el.current as any).__layer = layer // read by the browser test harness
    return () => { cancelAnimationFrame(raf); layerRef.current = undefined; mapRef.current = undefined; map.remove() }
  }, [pos]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { if (frame) layerRef.current?.setFrame(frame) }, [frame, pos])
  useEffect(() => { layerRef.current?.setMode(mode) }, [mode])
  useEffect(() => {
    const map = mapRef.current; if (!map) return
    if (basemap && !tileRef.current) tileRef.current = L.tileLayer(DARK_TILES, { attribution: '© OpenStreetMap contributors © CARTO', subdomains: 'abcd', maxZoom: 19 })
    if (tileRef.current) { if (basemap) tileRef.current.addTo(map).bringToBack(); else map.removeLayer(tileRef.current) }
  }, [basemap])

  return (
    <>
      <div ref={el} data-testid="viewer-map" style={{ background: '#0e1720' }} className="absolute inset-0" role="application" aria-label="Map of agents at their home locations" />
      {tip && (
        <div className="pointer-events-none absolute z-[700] -translate-x-1/2 -translate-y-full whitespace-nowrap rounded-md border border-nav-line bg-nav px-2.5 py-1.5 text-[11px] shadow-xl" style={{ left: tip.x, top: tip.y - 10 }}>
          {tip.info.kind === 'cell'
            ? <div className="space-y-0.5"><div className="text-nav-mute">Grid cell · {nf(tip.info.counts.reduce((a, b) => a + b, 0))} agents</div>{KEYS.map((k, i) => <div key={k} className="flex items-center gap-2"><span className="h-2 w-2 rounded-full" style={{ background: SEIR[k] }} />{SEIR_NAMES[k]}<span className="ml-auto pl-3 font-mono">{nf((tip.info as { counts: number[] }).counts[i])}</span></div>)}</div>
            : <div><div><b>Agent #{tip.info.id}</b> · {SEIR_NAMES[KEYS[tip.info.state]]}</div><div className="text-nav-mute">fixed home {tip.info.lat.toFixed(5)}, {tip.info.lon.toFixed(5)}</div></div>}
        </div>
      )}
    </>
  )
}
