import { useEffect, useState } from 'react'
import { BookOpen, Cpu, ShieldCheck, Zap } from 'lucide-react'
import { useApi } from '../api/client'
import type { Benchmarks } from '../api/types'
import type { Perf } from '../lib/perf'
import { ErrorState, PageHeader, PageSkeleton } from '../components/ui'
import ArchitectureExplorer from '../components/perf/ArchitectureExplorer'
import BenchmarkExplorer from '../components/perf/BenchmarkExplorer'
import CudaDeepDive from '../components/perf/CudaDeepDive'
import Correctness from '../components/perf/Correctness'

const TABS = [
  { id: 'arch', label: 'Architecture', icon: BookOpen },
  { id: 'bench', label: 'Benchmarks', icon: Cpu },
  { id: 'cuda', label: 'CUDA deep dive', icon: Zap },
  { id: 'ok', label: 'Correctness', icon: ShieldCheck },
] as const
type Tab = (typeof TABS)[number]['id']

export default function GPUPerformance() {
  const initial = (): Tab => TABS.find((t) => t.id === location.hash.split('/')[1])?.id ?? 'arch'
  const [tab, setTabState] = useState<Tab>(initial)
  const setTab = (t: Tab) => { setTabState(t); history.replaceState(null, '', `#gpu/${t}`) }
  // Back/forward or a pasted link that only changes the sub-path (#gpu/ok) must switch the tab without remounting the page.
  useEffect(() => {
    const h = () => { const t = TABS.find((x) => x.id === location.hash.split('/')[1])?.id; if (t) setTabState(t) }
    addEventListener('hashchange', h)
    return () => removeEventListener('hashchange', h)
  }, [])
  const bench = useApi<Benchmarks>('/api/benchmarks')
  const perf = useApi<Perf>('/api/perf')
  const loading = bench.loading || perf.loading
  const err = bench.error ?? perf.error
  return (
    <>
      <PageHeader subtitle="PAGP — Parallel Architectures &amp; GPU Programming — in CityEpi-GPU: how each implementation V0–V6 works, what was measured, and what the measurements do and do not show. All charts use recorded benchmark artifacts; nothing is executed or extrapolated here. V7/V8 (MPI) are future scope." />
      <div role="tablist" aria-label="Performance Lab sections" className="mb-5 flex gap-1 overflow-x-auto rounded-xl border border-line bg-surface p-1 shadow-card">
        {TABS.map(({ id, label, icon: Icon }) => (
          <button key={id} role="tab" aria-selected={tab === id} onClick={() => setTab(id)}
            className={`inline-flex shrink-0 items-center gap-2 rounded-lg px-3.5 py-2 text-sm font-medium transition duration-150 ${tab === id ? 'bg-nav text-white shadow-sm' : 'text-ink-2 hover:bg-surface-2'}`}>
            <Icon size={15} />{label}
          </button>
        ))}
      </div>
      {tab === 'arch' ? <div className="animate-fade-up"><ArchitectureExplorer /></div>
        : loading ? <PageSkeleton />
        : err || !bench.data || !perf.data ? <ErrorState error={err} onRetry={() => { bench.reload?.(); perf.reload?.() }} />
        : <div key={tab} className="animate-fade-up">
            {tab === 'bench' && <BenchmarkExplorer bench={bench.data} perf={perf.data} />}
            {tab === 'cuda' && <CudaDeepDive b={bench.data} />}
            {tab === 'ok' && <Correctness perf={perf.data} />}
          </div>}
    </>
  )
}
