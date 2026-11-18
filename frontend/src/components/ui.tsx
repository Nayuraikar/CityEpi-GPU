import { ReactNode } from 'react'
import { AlertTriangle, FlaskConical, Info, Inbox, RotateCw, ServerCrash } from 'lucide-react'
import type { Async } from '../api/client'
import { C } from '../lib/theme'

/* ───────── Layout ───────── */

/** Page lede. The page title lives in the app header; this carries the description + page-level actions. */
export function PageHeader({ subtitle, children }: { title?: string; subtitle?: string; children?: ReactNode }) {
  if (!subtitle && !children) return null
  return (
    <div className="mb-6 flex flex-wrap items-start justify-between gap-3">
      {subtitle && <p className="max-w-3xl text-[15px] leading-relaxed text-ink-2">{subtitle}</p>}
      {children}
    </div>
  )
}

export function SectionTitle({ title, sub, right }: { title: ReactNode; sub?: ReactNode; right?: ReactNode }) {
  return (
    <div className="mb-3 flex flex-wrap items-end justify-between gap-2">
      <div>
        <h2 className="text-base font-semibold text-ink">{title}</h2>
        {sub && <p className="mt-0.5 text-xs text-mute">{sub}</p>}
      </div>
      {right}
    </div>
  )
}

export function Card({ title, sub, right, children, className = '', hover = false }: { title?: ReactNode; sub?: ReactNode; right?: ReactNode; children: ReactNode; className?: string; hover?: boolean }) {
  return (
    <section className={`card p-4 sm:p-5 ${hover ? 'card-hover' : ''} ${className}`}>
      {(title || right) && (
        <header className="mb-4 flex items-start justify-between gap-3">
          <div className="min-w-0">
            {title && <h2 className="text-sm font-semibold text-ink">{title}</h2>}
            {sub && <p className="mt-0.5 text-xs leading-relaxed text-mute">{sub}</p>}
          </div>
          {right && <div className="shrink-0">{right}</div>}
        </header>
      )}
      {children}
    </section>
  )
}

/* ───────── Metrics ───────── */

export function InfoTip({ children }: { children: ReactNode }) {
  return (
    <span className="group relative inline-flex align-middle">
      <button type="button" aria-label="More information" className="text-mute/70 transition hover:text-teal-600 focus-visible:text-teal-600"><Info size={13} /></button>
      <span role="tooltip" className="pointer-events-none absolute bottom-full left-1/2 z-50 mb-2 w-56 -translate-x-1/2 translate-y-1 rounded-lg border border-line bg-surface p-2.5 text-left text-xs font-normal normal-case leading-relaxed tracking-normal text-ink-2 opacity-0 shadow-pop transition duration-150 group-hover:translate-y-0 group-hover:opacity-100 group-focus-within:translate-y-0 group-focus-within:opacity-100">
        {children}
      </span>
    </span>
  )
}

export function Stat({ label, value, sub, color = C.teal, hint }: { label: string; value: ReactNode; sub?: ReactNode; color?: string; hint?: ReactNode }) {
  return (
    <div className="card card-hover relative overflow-hidden p-4 pl-5">
      <span className="absolute inset-y-3 left-0 w-[3px] rounded-r-full" style={{ background: color }} />
      <div className="label flex items-center gap-1.5">{label}{hint && <InfoTip>{hint}</InfoTip>}</div>
      <div className="num mt-1.5 whitespace-nowrap text-[26px] font-semibold leading-none text-ink">{value}</div>
      {sub && <div className="mt-2 text-xs leading-snug text-mute">{sub}</div>}
    </div>
  )
}

/* ───────── Controls ───────── */

export function Segmented<T extends string | number>({ options, value, onChange, label, mono = false }: { options: { id: T; label: ReactNode; color?: string }[]; value: T; onChange: (v: T) => void; label?: string; mono?: boolean }) {
  return (
    <div className="flex flex-wrap items-center gap-2">
      {label && <span className="label">{label}</span>}
      <div role="tablist" aria-label={label} className="inline-flex flex-wrap gap-0.5 rounded-lg bg-surface-3 p-0.5">
        {options.map((o) => {
          const on = o.id === value
          return (
            <button key={String(o.id)} role="tab" aria-selected={on} onClick={() => onChange(o.id)}
              className={`${mono ? 'num' : ''} inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition duration-150 ${on ? 'bg-surface text-ink shadow-sm' : 'text-mute hover:text-ink'}`}>
              {o.color && <span className="h-2 w-2 rounded-full" style={{ background: o.color }} />}
              {o.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}

export function ToggleChip({ on, onClick, color = C.teal, children }: { on: boolean; onClick: () => void; color?: string; children: ReactNode }) {
  return (
    <button onClick={onClick} aria-pressed={on}
      className="inline-flex items-center gap-1.5 rounded-md border px-2 py-1 text-xs font-medium transition duration-150 hover:shadow-sm"
      style={on ? { borderColor: color, background: color + '1a', color } : { borderColor: C.line, color: C.axis }}>
      <span className="h-1.5 w-1.5 rounded-full transition" style={{ background: on ? color : C.line }} />{children}
    </button>
  )
}

export function Switch({ on, onChange, label }: { on: boolean; onChange: () => void; label: string }) {
  return (
    <button role="switch" aria-checked={on} aria-label={label} onClick={onChange}
      className={`relative h-[18px] w-8 shrink-0 rounded-full transition-colors duration-200 ${on ? 'bg-teal-500' : 'bg-line-2'}`}>
      <span className={`absolute top-[2px] h-[14px] w-[14px] rounded-full bg-white shadow transition-all duration-200 ${on ? 'left-[16px]' : 'left-[2px]'}`} />
    </button>
  )
}

/* ───────── Status & feedback ───────── */

export function Experimental({ children = 'Experimental assumption' }: { children?: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1 whitespace-nowrap rounded-full border border-amber/30 bg-amber-soft px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-amber-deep">
      <FlaskConical size={11} /> {children}
    </span>
  )
}

/** Provenance chip: where a number or layer comes from. Keeps real / synthetic / recorded / live visibly separate. */
const SOURCE = {
  osm: { label: 'Real · OpenStreetMap', cls: 'border-glacier/30 bg-glacier-soft text-glacier-deep' },
  synthetic: { label: 'Synthetic', cls: 'border-amber/30 bg-amber-soft text-amber-deep' },
  recorded: { label: 'Recorded result', cls: 'border-teal-500/30 bg-teal-50 text-teal-700' },
  live: { label: 'Live simulation', cls: 'border-coral/30 bg-coral-soft text-coral-deep' },
} as const
export function Source({ kind, children }: { kind: keyof typeof SOURCE; children?: ReactNode }) {
  const m = SOURCE[kind]
  return <span className={`inline-flex items-center whitespace-nowrap rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${m.cls}`}>{children ?? m.label}</span>
}

export function Notice({ children, tone = 'warn' }: { children: ReactNode; tone?: 'warn' | 'info' }) {
  const c = tone === 'warn' ? 'border-amber/30 bg-amber-soft text-amber-deep' : 'border-glacier/30 bg-glacier-soft text-glacier-deep'
  const Icon = tone === 'warn' ? AlertTriangle : Info
  return (
    <div role="note" className={`flex gap-2.5 rounded-lg border px-3.5 py-2.5 text-xs leading-relaxed ${c}`}>
      <Icon size={14} className="mt-0.5 shrink-0" />
      <div>{children}</div>
    </div>
  )
}

export function Badge({ children, color = C.teal }: { children: ReactNode; color?: string }) {
  return <span className="inline-flex items-center rounded-md px-1.5 py-0.5 text-[11px] font-medium" style={{ background: color + '1f', color: C.ink }}><span className="mr-1.5 h-1.5 w-1.5 rounded-full" style={{ background: color }} />{children}</span>
}

export function Dot({ color }: { color: string }) {
  return <span className="mr-2 inline-block h-2 w-2 shrink-0 rounded-full align-middle" style={{ background: color }} />
}

export function EmptyState({ title = 'Nothing recorded for this selection', children }: { title?: string; children?: ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center gap-1.5 rounded-lg border border-dashed border-line-2 bg-surface-2 px-6 py-10 text-center">
      <Inbox size={20} className="text-mute/60" />
      <div className="text-sm font-medium text-ink-2">{title}</div>
      {children && <div className="max-w-sm text-xs text-mute">{children}</div>}
    </div>
  )
}

export function ErrorState({ error, onRetry }: { error?: string; onRetry?: () => void }) {
  return (
    <div className="card mx-auto flex max-w-lg flex-col items-center gap-2 px-6 py-10 text-center animate-fade-up">
      <span className="grid h-10 w-10 place-items-center rounded-full bg-coral-soft text-coral-deep"><ServerCrash size={18} /></span>
      <h2 className="text-sm font-semibold">Could not load recorded data</h2>
      <p className="text-xs leading-relaxed text-mute">{error ?? 'No data returned.'}<br />Is the FastAPI backend running on port 8000?{error?.includes('404') && <><br /><b>A 404 usually means the API server was started before the latest code — restart it.</b></>}</p>
      {onRetry && <button className="btn btn-primary mt-2" onClick={onRetry}><RotateCw size={12} /> Retry</button>}
    </div>
  )
}

export function Skeleton({ className = '' }: { className?: string }) {
  return <div className={`skeleton ${className}`} />
}

export function PageSkeleton() {
  return (
    <div className="space-y-5" role="status" aria-label="Loading recorded data">
      <Skeleton className="h-10 w-2/3" />
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">{[0, 1, 2, 3].map((i) => <Skeleton key={i} className="h-[92px]" />)}</div>
      <div className="grid gap-5 lg:grid-cols-3"><Skeleton className="h-72 lg:col-span-2" /><Skeleton className="h-72" /></div>
    </div>
  )
}

export function Loaded<T>({ state, children }: { state: Async<T>; children: (d: T) => ReactNode }) {
  if (state.loading) return <PageSkeleton />
  if (state.error || !state.data) return <ErrorState error={state.error} onRetry={state.reload} />
  return <div className="animate-fade-up">{children(state.data)}</div>
}

/* ───────── Chart styling ───────── */

export const axis = { stroke: C.axis, fontSize: 11, tickLine: false, axisLine: { stroke: C.line } } as const
export const grid = { stroke: C.grid, strokeDasharray: '3 4' }
export const axisLabel = (value: string) => ({ value, position: 'insideBottomRight' as const, offset: -4, fill: C.axis, fontSize: 11 })
export const legendStyle = { fontSize: 12, color: C.axis }
export const tooltipStyle = {
  contentStyle: { background: '#fff', border: `1px solid ${C.line}`, borderRadius: 10, fontSize: 12, boxShadow: '0 8px 24px -8px rgba(23,33,44,.25)', padding: '8px 10px' },
  labelStyle: { color: C.axis, fontWeight: 600, marginBottom: 2 },
  itemStyle: { padding: 0, color: C.ink },
  cursor: { fill: 'rgba(47,154,147,.07)' },
}
