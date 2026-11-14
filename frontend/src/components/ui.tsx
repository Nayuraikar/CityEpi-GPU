import { ReactNode } from 'react'
import { AlertTriangle, FlaskConical, Loader2 } from 'lucide-react'
import type { Async } from '../api/client'

export function PageHeader({ title, subtitle, children }: { title: string; subtitle?: string; children?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
        {subtitle && <p className="mt-1 max-w-3xl text-sm text-mute">{subtitle}</p>}
      </div>
      {children}
    </div>
  )
}

export function Card({ title, sub, right, children, className = '' }: { title?: string; sub?: string; right?: ReactNode; children: ReactNode; className?: string }) {
  return (
    <section className={`card p-4 sm:p-5 ${className}`}>
      {(title || right) && (
        <header className="mb-3 flex items-start justify-between gap-3">
          <div>
            {title && <h2 className="text-sm font-semibold">{title}</h2>}
            {sub && <p className="mt-0.5 text-xs text-mute">{sub}</p>}
          </div>
          {right}
        </header>
      )}
      {children}
    </section>
  )
}

export function Stat({ label, value, sub, color }: { label: string; value: ReactNode; sub?: ReactNode; color?: string }) {
  return (
    <div className="card relative overflow-hidden p-4">
      <div className="absolute inset-x-0 top-0 h-px" style={{ background: `linear-gradient(90deg, ${color ?? '#5eead4'}, transparent)` }} />
      <div className="label">{label}</div>
      <div className="num mt-1.5 text-2xl font-semibold" style={color ? { color } : undefined}>{value}</div>
      {sub && <div className="mt-1 text-xs text-mute">{sub}</div>}
    </div>
  )
}

export function Experimental({ children = 'Experimental assumption' }: { children?: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full border border-amber-400/30 bg-amber-400/10 px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide text-amber-300">
      <FlaskConical size={11} /> {children}
    </span>
  )
}

export function Notice({ children, tone = 'warn' }: { children: ReactNode; tone?: 'warn' | 'info' }) {
  const c = tone === 'warn' ? 'border-amber-400/25 bg-amber-400/5 text-amber-200' : 'border-sky-400/25 bg-sky-400/5 text-sky-200'
  return (
    <div className={`flex gap-2 rounded-lg border px-3 py-2 text-xs leading-relaxed ${c}`}>
      <AlertTriangle size={14} className="mt-0.5 shrink-0" />
      <div>{children}</div>
    </div>
  )
}

export function Loaded<T>({ state, children }: { state: Async<T>; children: (d: T) => ReactNode }) {
  if (state.loading) return <div className="flex h-64 items-center justify-center gap-2 text-mute"><Loader2 className="animate-spin" size={18} /> Loading recorded data…</div>
  if (state.error || !state.data) return <Notice>Could not load data: {state.error}. Is the FastAPI backend running on port 8000?</Notice>
  return <>{children(state.data)}</>
}

export function Badge({ children, color = '#5eead4' }: { children: ReactNode; color?: string }) {
  return <span className="rounded-md px-1.5 py-0.5 text-[11px] font-medium" style={{ background: color + '22', color }}>{children}</span>
}

export const axis = { stroke: '#8b9ab8', fontSize: 11 }
export const grid = { stroke: '#1f2b45', strokeDasharray: '3 3' }
export const tooltipStyle = {
  contentStyle: { background: '#0e1524', border: '1px solid #1f2b45', borderRadius: 8, fontSize: 12 },
  labelStyle: { color: '#8b9ab8' },
  itemStyle: { padding: 0 },
  cursor: { fill: 'rgba(94,234,212,.06)' },
}
