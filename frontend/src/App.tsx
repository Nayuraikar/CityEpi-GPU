import { useEffect, useState } from 'react'
import { Activity, BarChart3, Cpu, Gauge, Layers, Map, Menu, Users, X } from 'lucide-react'
import Overview from './pages/Overview'
import GISExplorer from './pages/GISExplorer'
import EpidemicAnalysis from './pages/EpidemicAnalysis'
import PopulationExplorer from './pages/PopulationExplorer'
import ScenarioComparison from './pages/ScenarioComparison'
import GPUPerformance from './pages/GPUPerformance'

const PAGES = [
  { id: 'overview', label: 'Overview', icon: Gauge, el: Overview },
  { id: 'gis', label: 'GIS Explorer', icon: Map, el: GISExplorer },
  { id: 'epidemic', label: 'Epidemic Analysis', icon: Activity, el: EpidemicAnalysis },
  { id: 'population', label: 'Population Explorer', icon: Users, el: PopulationExplorer },
  { id: 'scenarios', label: 'Scenario Comparison', icon: Layers, el: ScenarioComparison },
  { id: 'gpu', label: 'GPU Performance', icon: Cpu, el: GPUPerformance },
] as const

const fromHash = () => PAGES.find((p) => p.id === location.hash.slice(1))?.id ?? 'overview'

export default function App() {
  const [page, setPage] = useState<string>(fromHash())
  const [open, setOpen] = useState(false)
  useEffect(() => {
    const h = () => setPage(fromHash())
    addEventListener('hashchange', h)
    return () => removeEventListener('hashchange', h)
  }, [])
  const Cur = PAGES.find((p) => p.id === page)!.el

  const nav = (
    <nav className="flex flex-col gap-1 p-3">
      {PAGES.map(({ id, label, icon: Icon }) => (
        <a key={id} href={`#${id}`} onClick={() => setOpen(false)}
          className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition ${page === id ? 'bg-accent/10 text-accent' : 'text-mute hover:bg-panel2 hover:text-ink'}`}>
          <Icon size={16} /> {label}
        </a>
      ))}
    </nav>
  )

  return (
    <div className="flex min-h-full">
      <aside className="sticky top-0 hidden h-screen w-60 shrink-0 flex-col border-r border-line bg-panel/60 backdrop-blur lg:flex">
        <Brand />
        {nav}
        <Foot />
      </aside>
      {open && (
        <div className="fixed inset-0 z-[2000] lg:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={() => setOpen(false)} />
          <aside className="relative h-full w-64 border-r border-line bg-panel">
            <button className="absolute right-3 top-4 text-mute" onClick={() => setOpen(false)}><X size={18} /></button>
            <Brand />{nav}
          </aside>
        </div>
      )}
      <div className="min-w-0 flex-1">
        <header className="sticky top-0 z-[1000] flex items-center gap-3 border-b border-line bg-bg/80 px-4 py-3 backdrop-blur lg:hidden">
          <button onClick={() => setOpen(true)}><Menu size={20} /></button>
          <span className="text-sm font-semibold">CityEpi-GPU</span>
        </header>
        <main className="mx-auto max-w-[1500px] p-4 sm:p-6 lg:p-8"><Cur /></main>
      </div>
    </div>
  )
}

function Brand() {
  return (
    <div className="flex items-center gap-2.5 border-b border-line px-5 py-5">
      <div className="grid h-8 w-8 place-items-center rounded-lg bg-gradient-to-br from-accent to-S text-bg"><BarChart3 size={18} /></div>
      <div>
        <div className="text-sm font-semibold leading-tight">CityEpi-GPU</div>
        <div className="text-[11px] text-mute">Bengaluru Urban · results dashboard</div>
      </div>
    </div>
  )
}

function Foot() {
  return (
    <div className="mt-auto border-t border-line p-4 text-[11px] leading-relaxed text-mute">
      Synthetic population — not census data. All epidemic parameters are experimental. Visualises recorded results; does not run simulations.
    </div>
  )
}
