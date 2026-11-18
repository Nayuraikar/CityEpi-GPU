import { ReactNode, useMemo, useState } from 'react'
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import type { BenchRow, Benchmarks } from '../../api/types'
import { Badge, Card, EmptyState, Notice, Segmented, axis, grid, legendStyle, tooltipStyle } from '../ui'
import { compact, nf, secs, x } from '../../lib/format'
import { C } from '../../lib/theme'

/* Variant keys follow bench_v6: E1 aggregation · E2 async/graph · E3 micro-opts · E4 block size. */
interface Opt { id: string; group: string; backend: string; title: string; what: string }
const OPTS: Opt[] = [
  { id: 'E1', group: 'E1', backend: 'V6_E1', title: 'Hierarchical state-count aggregation', what: 'warp ballot + popcount → shared memory → ≤4 global atomics per block' },
  { id: 'E2a', group: 'E2', backend: 'V6_E2_async', title: 'Asynchronous result transfer', what: 'no per-day host sync; one deferred copy of all daily counts' },
  { id: 'E2g32', group: 'E2', backend: 'V6_E2_graph32', title: 'CUDA Graph replay (32 days / graph)', what: 'both kernels of 32 days captured once and replayed' },
  { id: 'E2g1', group: 'E2', backend: 'V6_E2_graph1', title: 'CUDA Graph replay (1 day / graph)', what: 'one-day graph replayed 100 times' },
  { id: 'E3e', group: 'E3', backend: 'V6_E3_skipexp', title: 'Conditional exponential', what: 'skip exp() when a location’s infectious tally is 0 (result exactly +0)' },
  { id: 'E3r', group: 'E3', backend: 'V6_E3_skiprng', title: 'Conditional RNG', what: 'skip a random draw when the location probability is exactly 0' },
  { id: 'E3p', group: 'E3', backend: 'V6_E3_predload', title: 'Predicated location loads', what: 'load home/work ids only for agents that need them' },
  { id: 'E3a', group: 'E3', backend: 'V6_E3_all', title: 'All three E3 micro-optimisations', what: 'skip_exp + skip_rng + pred_loads' },
  { id: 'E4-64', group: 'E4', backend: 'V6_E4_b64', title: 'Block size 64', what: '2 warps per block' },
  { id: 'E4-128', group: 'E4', backend: 'V6_E4_b128', title: 'Block size 128', what: '4 warps per block' },
  { id: 'E4-512', group: 'E4', backend: 'V6_E4_b512', title: 'Block size 512', what: '16 warps per block' },
  { id: 'E4-1024', group: 'E4', backend: 'V6_E4_b1024', title: 'Block size 1024', what: '32 warps per block' },
  { id: 'C1', group: 'Combinations', backend: 'V6_E1_E2async', title: 'E1 + async', what: 'aggregation + deferred transfer' },
  { id: 'C2', group: 'Combinations', backend: 'V6_E1_E2graph', title: 'E1 + graph32', what: 'aggregation + graph replay' },
  { id: 'C3', group: 'Combinations', backend: 'V6_E1_E3', title: 'E1 + E3', what: 'aggregation + all E3' },
  { id: 'C4', group: 'Combinations', backend: 'V6_E1_E2graph_E3', title: 'E1 + graph32 + E3', what: 'aggregation + graph + all E3 (block 256)' },
  { id: 'C5', group: 'Combinations', backend: 'V6_E1_E2graph_E3_b128', title: 'E1 + graph32 + E3 + block 128', what: 'combination at block 128' },
  { id: 'C6', group: 'Combinations', backend: 'V6_E1_E2graph_E3_b512', title: 'E1 + graph32 + E3 + block 512', what: 'combination at block 512' },
  { id: 'C7', group: 'Combinations', backend: 'V6_E1_E2graph_E3_b1024', title: 'E1 + graph32 + E3 + block 1024', what: 'combination at block 1024' },
]

interface Gain { gain: number; sig: boolean; cv: number }
interface Evaluated { opt: Opt; cells: Record<number, Gain | undefined>; accept: boolean; acceptNo1M: boolean }

/** Verdict follows the repository’s own acceptance rule (bench/analyze_v6.py): improvement > max(3%, 2×CV) at ≥ 2 sizes and no regression worse than −2% at any size. */
function evaluate(rows: BenchRow[], scn: string, sizes: number[]): Evaluated[] {
  const at = (b: string, n: number) => rows.find((r) => r.scenario === scn && r.backend === b && r.agents === n)
  return OPTS.map((opt) => {
    const cells: Record<number, Gain | undefined> = {}
    for (const n of sizes) {
      const b = at('V6_base', n), v = at(opt.backend, n)
      if (!b || !v) continue
      const gain = 100 * (1 - v.kernel_median_s / b.kernel_median_s)
      const cv = Math.max(b.kernel_cv_pct, v.kernel_cv_pct)
      cells[n] = { gain, cv, sig: gain > Math.max(3, 2 * cv) }
    }
    const verdict = (ns: number[]) => { const c = ns.map((n) => cells[n]).filter(Boolean) as Gain[]; return c.filter((q) => q.sig).length >= 2 && c.every((q) => q.gain >= -2) }
    return { opt, cells, accept: verdict(sizes), acceptNo1M: verdict(sizes.filter((n) => n !== 1000000)) }
  })
}

const tint = (g: number) => (g >= 3 ? `rgba(47,154,147,${Math.min(0.55, 0.12 + g / 200)})` : g <= -2 ? `rgba(224,115,94,${Math.min(0.5, 0.12 + Math.abs(g) / 120)})` : 'transparent')

export default function CudaDeepDive({ b }: { b: Benchmarks }) {
  const [scn, setScn] = useState('default')
  const [n, setN] = useState(100000)
  const rows = b.v6_all_scenarios.rows
  const sizes = useMemo(() => [...new Set(rows.map((r) => r.agents))].sort((a, c) => a - c), [rows])
  const ev = useMemo(() => evaluate(rows, scn, sizes), [rows, scn, sizes])
  const prof = b.v6_profile_all.filter((r) => r.scenario === scn && r.agents === n)
  const at = (bk: string, k = n) => rows.find((r) => r.scenario === scn && r.backend === bk && r.agents === k)
  const pf = (bk: string, k = n) => b.v6_profile_all.find((r) => r.scenario === scn && r.backend === bk && r.agents === k)
  const v5 = at('V5'), base = at('V6_base'), e1 = at('V6_E1')
  const blocksSel = ['V6_E4_b64', 'V6_E4_b128', 'V6_base', 'V6_E4_b512', 'V6_E4_b1024']
  const blockData = sizes.map((k) => { const o: Record<string, number | null> = { agents: k }; const bb = at('V6_base', k)?.kernel_median_s; for (const bk of blocksSel) { const v = at(bk, k)?.kernel_median_s; o[bk] = v && bb ? 100 * (1 - v / bb) : null } return o })
  const bcol: Record<string, string> = { V6_E4_b64: C.lavender, V6_E4_b128: C.glacier, V6_base: C.slate, V6_E4_b512: C.amber, V6_E4_b1024: C.coral }
  const blabel: Record<string, string> = { V6_E4_b64: '64', V6_E4_b128: '128', V6_base: '256 (base)', V6_E4_b512: '512', V6_E4_b1024: '1024' }

  return (
    <div className="space-y-5">
      <Notice tone="info">All numbers on this tab come from <b>one recorded Kaggle Tesla T4 run</b> (<span className="num">kaggle_v6/v6_benchmark_all.csv</span>, nvcc 13.0, 7 repetitions, 100 days). “Gain” is the reduction in median kernel time versus <b>V6_base inside the same run</b>. Every variant’s output was recorded identical to V0 and V5.</Notice>

      <div className="card flex flex-wrap items-center gap-x-8 gap-y-3 p-3 sm:px-4">
        <Segmented label="Workload" value={scn} onChange={setScn} options={['default', 'low', 'high'].map((s) => ({ id: s, label: s }))} />
        <Segmented mono label="Agents" value={n} onChange={setN} options={sizes.map((s) => ({ id: s, label: compact(s) }))} />
        <span className="text-[11px] text-mute">default / low / high are the benchmark’s own β scenarios (they change the S/E/I/R mix over time).</span>
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {[['V5 kernel', secs(v5?.kernel_median_s), `${compact(n)} agents`, C.sage], ['V6 base', secs(base?.kernel_median_s), `${x(base?.kernel_speedup_v5)} vs V5`, C.slate],
          ['V6 E1 (aggregation only)', secs(e1?.kernel_median_s), `${x(e1?.kernel_speedup_v5)} vs V5`, C.teal],
          ['Step kernel, base → E1', `${nf(pf('V6_base')?.step_ms_median, 2)} → ${nf(pf('V6_E1')?.step_ms_median, 2)} ms`, '100-day total from the separate profiling pass', C.glacier]].map(([l, v, s, c]) => (
          <div key={String(l)} className="card relative overflow-hidden p-4 pl-5"><span className="absolute inset-y-3 left-0 w-[3px] rounded-r-full" style={{ background: String(c) }} /><div className="label">{l}</div><div className="num mt-1.5 text-xl font-semibold">{v}</div><div className="mt-1.5 text-xs text-mute">{s}</div></div>))}
      </div>

      <Card title="Optimisation ablation" sub={`${scn} workload · % reduction in median kernel time vs V6_base (positive = faster). ★ = beats max(3%, 2×CV).`}>
        <div className="overflow-x-auto"><table className="tbl tbl-sm text-xs">
          <thead><tr className="text-left"><th>Variant</th>{sizes.map((s) => <th key={s} className="px-1 text-right">{compact(s)}</th>)}<th className="pl-3">Rule verdict</th><th className="pl-2">excl. 1M</th></tr></thead>
          <tbody>{ev.map((e, i) => (
            <tr key={e.opt.id} className={i > 0 && ev[i - 1].opt.group !== e.opt.group ? 'border-t-2 border-line' : ''}>
              <td className="max-w-[300px] pr-3"><div className="font-medium">{e.opt.title}</div><div className="truncate text-[10px] text-mute" title={e.opt.what}>{e.opt.what}</div></td>
              {sizes.map((s) => { const c = e.cells[s]; return <td key={s} className="num px-1 text-right" style={{ background: c ? tint(c.gain) : undefined }}>{c ? `${c.gain >= 0 ? '+' : ''}${nf(c.gain, 0)}%${c.sig ? '★' : ''}` : '—'}</td> })}
              <td className="pl-3"><Badge color={e.accept ? C.sage : C.coral}>{e.accept ? 'accept' : 'reject'}</Badge></td>
              <td className="pl-2"><Badge color={e.acceptNo1M ? C.sage : C.coral}>{e.acceptNo1M ? 'accept' : 'reject'}</Badge></td>
            </tr>))}</tbody>
        </table></div>
        <div className="mt-3 space-y-2">
          <p className="text-[11px] leading-relaxed text-mute"><b>Rule</b> (<span className="num">bench/analyze_v6.py</span>): accepted when the gain exceeds max(3%, 2×CV) at ≥ 2 sizes with no size regressing by more than 2%. CV = the larger of the two rows’ coefficient of variation.</p>
          <Notice><b>1M-agent anomaly.</b> At 1M agents, V6_base (131 ms) is ≈35% slower than <i>every</i> other non-aggregating variant — including ones that should be neutral at that size (predicated loads, block 512/1024 → ≈85 ms) — and the same pattern appears in the second recorded CSV (<span className="num">v6_benchmark.csv</span>: 130 ms vs 85 ms). So the 1M column overstates the benefit of those options, and the cause is not explained by the recorded data. The “excl. 1M” column re-applies the rule to the other three sizes; compare the 1M rows against V5 (155 ms) rather than V6_base.</Notice>
        </div>
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Block-size experiment (E4)" sub={`${scn} workload · gain vs the 256-thread base, by population`}>
          <div className="h-[280px]"><ResponsiveContainer>
            <BarChart data={blockData} margin={{ left: 0, right: 8 }}>
              <CartesianGrid {...grid} vertical={false} /><XAxis dataKey="agents" {...axis} tickFormatter={compact} /><YAxis {...axis} unit="%" width={46} />
              <Tooltip {...tooltipStyle} formatter={(v: any, name) => [`${v >= 0 ? '+' : ''}${nf(v, 1)}%`, `block ${name}`]} labelFormatter={(a) => `${nf(a as number)} agents`} /><Legend wrapperStyle={legendStyle} />
              {blocksSel.filter((k) => k !== 'V6_base').map((k) => <Bar key={k} name={blabel[k]} dataKey={k} fill={bcol[k]} radius={[3, 3, 0, 0]} isAnimationActive={false} />)}
            </BarChart></ResponsiveContainer></div>
          <ul className="mt-2 list-disc space-y-1 pl-4 text-[11px] leading-relaxed text-mute">
            <li>Small blocks (64/128) help at 10k agents, large blocks (512/1024) hurt: with only {compact(10000)} agents, 1024-thread blocks give just {Math.ceil(10000 / 1024)} blocks for 40 SMs, likely leaving most of the GPU idle (the recorded kernel info shows 100% theoretical occupancy per SM at every block size, so register pressure does not explain it).</li>
            <li>From 100k agents the effect is within a few percent; 1M values are affected by the anomaly above.</li>
          </ul>
        </Card>

        <Card title="Where the time goes (profiling pass)" sub={`${compact(n)} agents · ${scn} · summed kernel time over the 100 days, ms`}>
          {prof.length === 0 ? <EmptyState title="No profile rows" /> : <div className="h-[330px]"><ResponsiveContainer>
            <BarChart data={prof.filter((r) => ['V6_base', 'V6_E1', 'V6_E2_async', 'V6_E3_skipexp', 'V6_E4_b64', 'V6_E1_E2graph_E3_b128'].includes(r.backend))} layout="vertical" margin={{ left: 10, right: 20 }}>
              <CartesianGrid {...grid} horizontal={false} /><XAxis type="number" {...axis} unit=" ms" /><YAxis type="category" dataKey="backend" {...axis} width={150} fontSize={10} interval={0} />
              <Tooltip {...tooltipStyle} formatter={(v: any) => `${nf(v, 3)} ms`} /><Legend wrapperStyle={legendStyle} />
              <Bar dataKey="loc_ms_median" name="location kernel" stackId="a" fill={C.lavender} isAnimationActive={false} />
              <Bar dataKey="step_ms_median" name="agent-step kernel" stackId="a" fill={C.teal} isAnimationActive={false} />
            </BarChart></ResponsiveContainer></div>}
          <p className="mt-2 text-[11px] text-mute">Profiling is a separate pass using CUDA events between the two kernels (<span className="num">prof_loc_ms / prof_step_ms</span> are sums over days), so it excludes the per-day count read-back and does not equal the kernel-time column.</p>
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Explain title="Warp ballot, popcount and hierarchical aggregation (E1)" gain={ev.find((e) => e.opt.id === 'E1')?.cells} sizes={sizes}>
          <p>In V5, <b>every agent</b> does <code>atomicAdd(&amp;counts[new_state], 1)</code>: N atomics onto just four words. They serialise in the memory system. E1 replaces them in three steps: (1) <code>__ballot_sync</code> builds a 32-bit mask of the warp’s lanes whose new state is <i>k</i> and <code>__popc</code> counts the bits; (2) lane 0 adds that count to a 4-word <code>__shared__</code> array; (3) after <code>__syncthreads()</code>, four threads add the block totals to global memory. Global atomics drop from N to ≤4 per block.</p>
          <p>Evidence: the agent-step kernel falls from {nf(pf('V6_base')?.step_ms_median, 2)} to {nf(pf('V6_E1')?.step_ms_median, 2)} ms (100-day total) at {compact(n)} agents in the profiling pass, while the location kernel is unchanged ({nf(pf('V6_base')?.loc_ms_median, 2)} vs {nf(pf('V6_E1')?.loc_ms_median, 2)} ms) — the gain is where the contended atomics were. It costs 4 extra registers (30→34) and 16 B of shared memory, with no occupancy loss (recorded). Output stays identical because integer sums are order-independent.</p>
        </Explain>
        <Explain title="Asynchronous transfer and CUDA Graph replay (E2)" gain={ev.find((e) => e.opt.id === 'E2g32')?.cells} sizes={sizes}>
          <p>V5/V6-base copy the 16-byte count array to the host <b>every day</b> and wait, which forces a device↔host synchronisation 100 times per run. E2a keeps all counts in a device array and copies them once at the end (conservation is checked afterwards). E2b additionally captures the two kernel launches of 32 days in a CUDA Graph and replays it, so the CPU submits one launch instead of 64.</p>
          <p>Evidence: large relative gains at 10k agents ({nf(ev.find((e) => e.opt.id === 'E2a')?.cells[10000]?.gain, 0)}% async, {nf(ev.find((e) => e.opt.id === 'E2g32')?.cells[10000]?.gain, 0)}% graph) where each day is only tens of microseconds of GPU work, shrinking to ≈15% at 100k and ≈0% at 5M where compute dominates. Graph vs plain async differs by only a few percent here — launch overhead was mostly the per-day sync, not the launches themselves. Graph build is counted in end-to-end, not kernel, time.</p>
        </Explain>
        <Explain title="Conditional exponential and RNG (E3)" gain={ev.find((e) => e.opt.id === 'E3a')?.cells} sizes={sizes}>
          <p><b>skip_exp:</b> a location with no infectious occupants has <code>exp(−β·0)=1</code>, so its probability is exactly +0; skipping the <code>exp</code> is bit-exact (tested: 0/240 bitwise differences). It helps the location kernel — at 10k the location kernel drops {nf(pf('V6_base', 10000)?.loc_ms_median, 2)} → {nf(pf('V6_E3_skipexp', 10000)?.loc_ms_median, 2)} ms. <b>skip_rng:</b> a draw <code>u ≥ 0</code> can never be &lt; 0, so skipping it when the location probability is exactly 0 changes nothing. <b>pred_loads:</b> only load home/work ids when needed.</p>
          <p>Evidence: skip_exp helps modestly; skip_rng and pred_loads are within noise on their own (the repository rule rejects them). Likely reason (a hypothesis, not measured): the saved work sits inside the divergent <code>s == S</code> branch and the kernel is dominated by atomics and memory gathers rather than arithmetic, so removing arithmetic barely moves the total — while E1 does.</p>
        </Explain>
        <Explain title="Why combinations compound" gain={ev.find((e) => e.opt.id === 'C4')?.cells} sizes={sizes}>
          <p>E1 removes the dominant cost (contended count atomics), which makes the previously hidden fixed costs visible: per-day synchronisation (E2) and the location kernel (E3). After E1, async/graph save a larger fraction of a much shorter run — at 10k, E1 alone is {nf(ev.find((e) => e.opt.id === 'E1')?.cells[10000]?.gain, 0)}% and E1+graph+E3 is {nf(ev.find((e) => e.opt.id === 'C4')?.cells[10000]?.gain, 0)}%. Block size 128 on top adds a few more points at 10k and is roughly neutral at larger sizes; 512/1024 are worse at small N.</p>
          <p>Kernel time ≠ end-to-end time. Default workload, 10k agents: the fastest variant’s kernel time is 0.93 ms but its end-to-end time is 1.42 ms (transfers and graph build), so the headline kernel speedup (31× vs V0) corresponds to ≈20× end-to-end in the same run. See the Benchmarks tab for the full kernel-vs-end-to-end table.</p>
        </Explain>
      </div>
    </div>
  )
}

function Explain({ title, children, gain, sizes }: { title: string; children: ReactNode; gain?: Record<number, { gain: number; sig: boolean } | undefined>; sizes: number[] }) {
  return (
    <Card title={title}>
      <div className="space-y-2.5 text-xs leading-relaxed text-ink-2 [&_code]:rounded [&_code]:bg-surface-3 [&_code]:px-1 [&_code]:font-mono [&_code]:text-[11px]">{children}</div>
      {gain && <div className="mt-3 flex flex-wrap gap-1.5">{sizes.map((s) => gain[s] && <span key={s} className="num rounded-md border border-line px-1.5 py-0.5 text-[10px] text-mute">{compact(s)}: <b className={gain[s]!.gain < -2 ? 'text-coral-deep' : 'text-ink'}>{gain[s]!.gain >= 0 ? '+' : ''}{nf(gain[s]!.gain, 0)}%</b></span>)}</div>}
    </Card>
  )
}
