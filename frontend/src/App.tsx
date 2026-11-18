import { useEffect, useState } from 'react'
import { Activity, Radio, Rocket, Cpu, FlaskConical, Gauge, Layers, Map, Menu, PanelLeftClose, PanelLeftOpen, Users, X } from 'lucide-react'
import Overview from './pages/Overview'
import GISExplorer from './pages/GISExplorer'
import EpidemicAnalysis from './pages/EpidemicAnalysis'
import PopulationExplorer from './pages/PopulationExplorer'
import ScenarioComparison from './pages/ScenarioComparison'
import GPUPerformance from './pages/GPUPerformance'
import SimulationStudio from './pages/SimulationStudio'

const PAGES = [
  { id: 'overview', group: 'Workspace', label: 'Overview', title: 'Project Overview', icon: Gauge, el: Overview, ctx: 'Synthetic Bengaluru Urban · recorded results' },
  { id: 'gis', group: 'Explore', label: 'GIS Explorer', title: 'Bengaluru GIS Explorer', icon: Map, el: GISExplorer, ctx: 'OpenStreetMap layers + synthetic locations' },
  { id: 'population', group: 'Explore', label: 'Population Explorer', title: 'Population Explorer', icon: Users, el: PopulationExplorer, ctx: 'Synthetic population · not census data' },
  { id: 'epidemic', group: 'Analyse', label: 'Epidemic Analysis', title: 'Epidemic Analysis', icon: Activity, el: EpidemicAnalysis, ctx: 'V6 CUDA recorded runs' },
  { id: 'scenarios', group: 'Analyse', label: 'Scenario Comparison', title: 'Scenario Comparison', icon: Layers, el: ScenarioComparison, ctx: 'Seed 42 runs + 10-seed validation' },
  { id: 'gpu', group: 'Performance', label: 'PAGP Performance Lab', title: 'PAGP Performance Lab', icon: Cpu, el: GPUPerformance, ctx: 'V0–V6 architecture · recorded M1 + Kaggle T4 benchmarks' },
  { id: 'studio', group: 'Simulate', label: 'Simulation Studio', title: 'Simulation Studio', icon: Rocket, el: SimulationStudio, ctx: 'Live runs of extpop_run on this host' },
] as const

const GROUPS = ['Workspace', 'Explore', 'Analyse', 'Performance', 'Simulate']
const fromHash = () => PAGES.find((p) => p.id === location.hash.slice(1).split('/')[0])?.id ?? 'overview'
const stored = () => { try { return localStorage.getItem('cityepi-nav') === '1' } catch { return false } }

export default function App() {
  const [page, setPage] = useState<string>(fromHash())
  const [drawer, setDrawer] = useState(false)
  const [collapsed, setCollapsed] = useState(stored)
  useEffect(() => {
    const h = () => { setPage(fromHash()); window.scrollTo({ top: 0 }) }
    addEventListener('hashchange', h)
    return () => removeEventListener('hashchange', h)
  }, [])
  useEffect(() => { try { localStorage.setItem('cityepi-nav', collapsed ? '1' : '0') } catch { /* storage unavailable */ } }, [collapsed])
  useEffect(() => {
    const k = (e: KeyboardEvent) => e.key === 'Escape' && setDrawer(false)
    addEventListener('keydown', k)
    return () => removeEventListener('keydown', k)
  }, [])

  const cur = PAGES.find((p) => p.id === page)!
  useEffect(() => { document.title = `${cur.title} · CityEpi-GPU` }, [cur])
  const Cur = cur.el

  return (
    <div className="flex min-h-full">
      {/* Desktop sidebar */}
      <aside className={`sticky top-0 z-40 hidden h-screen shrink-0 flex-col bg-nav text-nav-ink transition-[width] duration-300 ease-out lg:flex ${collapsed ? 'w-[72px]' : 'w-64'}`}>
        <Brand collapsed={collapsed} />
        <Nav page={page} collapsed={collapsed} />
        <SideFoot collapsed={collapsed} onToggle={() => setCollapsed(!collapsed)} />
      </aside>

      {/* Mobile drawer */}
      <div className={`fixed inset-0 z-[2000] lg:hidden ${drawer ? '' : 'pointer-events-none'}`} aria-hidden={!drawer}>
        <div className={`absolute inset-0 bg-nav/60 backdrop-blur-sm transition-opacity duration-200 ${drawer ? 'opacity-100' : 'opacity-0'}`} onClick={() => setDrawer(false)} />
        <aside className={`relative flex h-full w-72 max-w-[85vw] flex-col bg-nav text-nav-ink shadow-pop transition-transform duration-300 ease-out ${drawer ? 'translate-x-0' : '-translate-x-full'}`}>
          <button aria-label="Close menu" className="absolute right-3 top-4 rounded-md p-1 text-nav-mute hover:text-white" onClick={() => setDrawer(false)}><X size={18} /></button>
          <Brand collapsed={false} />
          <Nav page={page} collapsed={false} onNavigate={() => setDrawer(false)} />
          <SideFoot collapsed={false} />
        </aside>
      </div>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 border-b border-line bg-surface/85 backdrop-blur-md">
          <div className="mx-auto flex max-w-[1480px] items-center gap-3 px-4 py-3 sm:px-6 lg:px-8">
            <button aria-label="Open menu" onClick={() => setDrawer(true)} className="-ml-1 rounded-md p-1.5 text-ink-2 hover:bg-surface-3 lg:hidden"><Menu size={20} /></button>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-[0.08em] text-mute">
                <span>{cur.group}</span><span aria-hidden>/</span><span className="truncate">{cur.ctx}</span>
              </div>
              <h1 className="truncate text-lg font-semibold leading-tight sm:text-xl">{cur.title}</h1>
            </div>
            <div className="hidden items-center gap-2 md:flex">
              <span title="Simulation Studio launches real extpop_run executions on this host. Other pages show recorded results." className="inline-flex items-center gap-1.5 rounded-full border border-line bg-surface-2 px-2.5 py-1 text-[11px] font-medium text-ink-2"><Radio size={11} /> Live simulation enabled</span>
              <span title="Synthetic population — not actual census data. Epidemic parameters are experimental." className="inline-flex items-center gap-1.5 rounded-full border border-amber/30 bg-amber-soft px-2.5 py-1 text-[11px] font-medium text-amber-deep"><FlaskConical size={11} /> Synthetic · experimental</span>
            </div>
          </div>
        </header>
        <main key={page} className="mx-auto w-full max-w-[1480px] flex-1 animate-fade-up px-4 py-6 sm:px-6 lg:px-8 lg:py-8"><Cur /></main>
      </div>
    </div>
  )
}

function Logo() {
  return (
    <svg viewBox="0 0 36 36" className="h-9 w-9 shrink-0" aria-hidden>
      <defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#52b0a8" /><stop offset="1" stopColor="#23807a" /></linearGradient></defs>
      <rect width="36" height="36" rx="9" fill="url(#lg)" />
      <g fill="#fff" fillOpacity=".28"><rect x="7" y="19" width="5" height="10" rx="1" /><rect x="15.5" y="13" width="5" height="16" rx="1" /><rect x="24" y="22" width="5" height="7" rx="1" /></g>
      <path d="M6 24 C 11 24, 12 11, 18 11 S 25 24, 30 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" />
      <circle cx="18" cy="11" r="2.2" fill="#fff" />
    </svg>
  )
}

function Brand({ collapsed }: { collapsed: boolean }) {
  return (
    <div className={`flex h-[72px] items-center gap-3 border-b border-nav-line ${collapsed ? 'justify-center' : 'px-5'}`}>
      <Logo />
      {!collapsed && (
        <div className="min-w-0 animate-fade-up">
          <div className="text-[15px] font-semibold leading-tight tracking-tight text-white">CityEpi<span className="text-teal-400">-GPU</span></div>
          <div className="truncate text-[11px] text-nav-mute">Geospatial epidemic simulation</div>
        </div>
      )}
    </div>
  )
}

function Nav({ page, collapsed, onNavigate }: { page: string; collapsed: boolean; onNavigate?: () => void }) {
  return (
    <nav className="flex-1 overflow-y-auto px-3 py-4" aria-label="Primary">
      {GROUPS.map((g) => (
        <div key={g} className="mb-4">
          {collapsed ? <div className="mx-3 mb-2 h-px bg-nav-line" /> : <div className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-[0.12em] text-nav-mute/70">{g}</div>}
          <ul className="space-y-0.5">
            {PAGES.filter((p) => p.group === g).map(({ id, label, icon: Icon }) => {
              const on = page === id
              return (
                <li key={id}>
                  <a href={`#${id}`} onClick={onNavigate} title={collapsed ? label : undefined} aria-current={on ? 'page' : undefined}
                    className={`group relative flex items-center gap-3 rounded-lg py-2 text-[13px] font-medium transition-colors duration-150 ${collapsed ? 'justify-center px-0' : 'px-3'} ${on ? 'bg-nav-3 text-white' : 'text-nav-mute hover:bg-nav-2 hover:text-white'}`}>
                    <span className={`absolute left-0 top-1/2 w-[3px] -translate-y-1/2 rounded-r-full bg-teal-400 transition-all duration-200 ${on ? 'h-5 opacity-100' : 'h-0 opacity-0'}`} />
                    <Icon size={17} className={`shrink-0 transition-colors ${on ? 'text-teal-400' : 'group-hover:text-teal-200'}`} />
                    {!collapsed && <span className="truncate">{label}</span>}
                  </a>
                </li>
              )
            })}
          </ul>
        </div>
      ))}
    </nav>
  )
}

function SideFoot({ collapsed, onToggle }: { collapsed: boolean; onToggle?: () => void }) {
  return (
    <div className="border-t border-nav-line p-3">
      {collapsed ? (
        <div className="mb-2 flex justify-center" title="Synthetic population — not census data. All epidemic parameters are experimental. Result pages show recorded data; Simulation Studio launches real runs.">
          <FlaskConical size={16} className="text-amber" />
        </div>
      ) : (
        <div className="mb-2 rounded-lg bg-nav-2 p-3 text-[11px] leading-relaxed text-nav-mute">
          <div className="mb-1 flex items-center gap-1.5 font-semibold text-amber"><FlaskConical size={12} /> Read this first</div>
          Synthetic population — not census data. All epidemic parameters are experimental. Result pages show recorded data; Simulation Studio launches real runs.
        </div>
      )}
      {onToggle && (
        <button onClick={onToggle} aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'} title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          className={`flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs text-nav-mute transition hover:bg-nav-2 hover:text-white ${collapsed ? 'justify-center px-0' : ''}`}>
          {collapsed ? <PanelLeftOpen size={16} /> : <><PanelLeftClose size={16} /> Collapse</>}
        </button>
      )}
    </div>
  )
}
