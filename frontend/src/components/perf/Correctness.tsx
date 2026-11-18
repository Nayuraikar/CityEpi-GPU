import { useApi } from '../../api/client'
import type { Runs } from '../../api/types'
import { Badge, Card, Notice, Skeleton } from '../ui'
import { C } from '../../lib/theme'
import type { Ident, Perf } from '../../lib/perf'

const ok = (i: Ident) => i.checked > 0 && i.checked === i.identical

function IdentRow({ label, where, i, hint }: { label: string; where: string; i: Ident; hint?: string }) {
  return (
    <tr>
      <td className="pr-3"><div className="font-medium">{label}</div><div className="num text-[10px] text-mute">{where}</div></td>
      <td className="num pr-3 text-right">{i.identical} / {i.checked}</td>
      <td><Badge color={ok(i) ? C.sage : C.coral}>{ok(i) ? 'all identical' : i.checked ? 'MISMATCH' : 'no data'}</Badge></td>
      <td className="pl-3 text-[11px] text-mute">{hint}</td>
    </tr>
  )
}

export default function Correctness({ perf }: { perf: Perf }) {
  const runs = useApi<Runs>('/api/epidemic')
  const c = perf.correctness
  return (
    <div className="space-y-5">
      <Notice tone="info"><b>What “identical” means here.</b> Every backend is compared with the V0 sequential reference using the daily S/E/I/R counts of the whole simulation (and, for the epidemic runs, a 64-bit daily checksum). The random numbers come from a <b>counter-based</b> generator keyed by (seed, agent, day, slot), and all reductions are integer sums — so results do not depend on thread count, scheduling, or the order in which GPU threads finish. Only configurations listed below were tested; absence from this page means <b>not tested</b>.</Notice>

      <Card title="Backend comparison counts" sub="Counted directly from the recorded benchmark CSV columns (identical / identical_v0 / identical_v5). Each row is one backend × population size × scenario.">
        <div className="overflow-x-auto"><table className="tbl tbl-sm text-xs">
          <thead><tr className="text-left"><th>Recorded set</th><th className="text-right">identical / checked</th><th>Status</th><th className="pl-3">Note</th></tr></thead>
          <tbody>
            <IdentRow label="V1, V2 (OpenMP) vs V0" where="bench/results/v2_results.csv · Apple M1" i={c.v2_v3_cpu_rows.v2_csv} hint="Thread counts 1–8 × schedules × reduction modes" />
            <IdentRow label="V1, V2, V3 scalar/NEON vs V0" where="bench/results/v3_results.csv · Apple M1" i={c.v2_v3_cpu_rows.v3_csv} />
            <IdentRow label="…including V3 hybrid" where="bench/results/v3_hybrid_results.csv · Apple M1" i={c.v2_v3_cpu_rows.v3_hybrid_csv} />
            <IdentRow label="V4 OpenACC and CPU rows vs V0" where="kaggle_v4/v4_gpu_results.csv · Tesla T4" i={c.v4.rows} />
            <IdentRow label="V5 CUDA and CPU rows vs V0" where="kaggle_v5/v5_benchmark.csv · Tesla T4" i={c.v5.rows} />
            <IdentRow label="V6 variants vs V0 and vs V5" where="kaggle_v6/v6_benchmark_all.csv · Tesla T4" i={c.v6.rows} hint="19 variants × 4 sizes × 3 workloads, two comparisons per row" />
          </tbody>
        </table></div>
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card title="Test-suite evidence (recorded on Kaggle T4)">
          <ul className="space-y-3 text-xs leading-relaxed text-ink-2">
            <li><b>V6:</b> {c.v6.test_comparisons != null ? <><span className="num">{c.v6.test_comparisons.toLocaleString()}</span> V6 comparisons on {c.v6.test_device}; “V6 OK”.</> : 'no test log found.'} Each is a V6 run compared with V0 (and V5): all option sets, block sizes 64–1024, partial-warp and block-tail sizes, several β values, determinism over repeated runs.</li>
            <li><b>V4:</b> {c.v4.test_comparisons != null ? <><span className="num">{c.v4.test_comparisons}</span> V4 comparisons [{c.v4.test_target}]; “V4 OK”.</> : 'no test log found.'}</li>
            <li><b>V6 E3 skip_exp exactness:</b> {c.v6.skip_exp ?? 'not recorded'}.</li>
            <li className="text-mute">Source logs: <span className="num">kaggle_v6/test_v6.log</span>, <span className="num">kaggle_v4/v4_gpu_test.log</span>. The CPU test executables (<span className="num">test_v0 … test_v3, test_external_input, test_extpop_*</span>) run locally with <span className="num">ctest</span> in a CPU build.</li>
          </ul>
        </Card>

        <Card title="Host vs device floating-point differences">
          <div className="space-y-3 text-xs leading-relaxed text-ink-2">
            <p>The infection probability is <code className="rounded bg-surface-3 px-1 font-mono text-[11px]">1 − exp(−β·n_inf/occ)</code>. GPU math libraries do not guarantee <code className="rounded bg-surface-3 px-1 font-mono text-[11px]">exp()</code> results bit-identical to the host libm, and the project does not claim they are. The tests print the difference <i>informationally</i>:</p>
            <table className="tbl tbl-sm"><tbody>
              {c.v6.fp && <tr><td>V6 (nvcc, T4)</td><td className="num text-right">{c.v6.fp.differ} / {c.v6.fp.of.toLocaleString()} values differ</td><td className="num pl-3 text-right text-mute">max rel. diff {c.v6.fp.max_rel}</td></tr>}
              {c.v4.fp && <tr><td>V4 (NVHPC, T4)</td><td className="num text-right">{c.v4.fp.differ} / {c.v4.fp.of.toLocaleString()} values differ</td><td className="num pl-3 text-right text-mute">max rel. diff {c.v4.fp.max_rel}</td></tr>}
            </tbody></table>
            <p>These ≈1e-15 relative differences only matter if they flip the decision <code className="rounded bg-surface-3 px-1 font-mono text-[11px]">u &lt; prob</code>; the authoritative check is that the daily counts equal V0’s in every recorded comparison above.</p>
          </div>
        </Card>
      </div>

      <Card title="V0 ↔ V6 equivalence on the Bengaluru epidemic runs" sub="Recorded Kaggle runs on the synthetic Bengaluru population (/api/epidemic). Equality is of every daily S/E/I/R count and of the 64-bit daily checksum.">
        {runs.loading ? <Skeleton className="h-32" /> : runs.error || !runs.data ? <p className="text-xs text-coral-deep">{runs.error ?? 'No data'}</p> : (
          <div className="overflow-x-auto"><table className="tbl tbl-sm text-xs">
            <thead><tr className="text-left"><th>Scenario</th><th className="text-right">Agents</th><th className="text-right">Days</th><th className="text-right">Seed</th><th>Daily checksum</th><th>V0 = V6</th><th>Device</th></tr></thead>
            <tbody>{Object.values(runs.data).map((r) => (
              <tr key={r.key}><td className="pr-3 font-medium">{r.label}</td><td className="num pr-3 text-right">{r.agents.toLocaleString()}</td><td className="num pr-3 text-right">{r.days}</td><td className="num pr-3 text-right">{r.seed}</td><td className="num pr-3">{r.daily_checksum}</td>
                <td className="pr-3"><Badge color={r.v0_v6_equal && r.curves_identical ? C.sage : C.coral}>{r.v0_v6_equal && r.curves_identical ? 'identical' : 'DIFFERENT'}</Badge></td><td className="text-mute">{r.v6_device}</td></tr>))}</tbody>
          </table></div>)}
      </Card>

      <Card title="What has not been tested">
        <ul className="list-disc space-y-1.5 pl-4 text-xs leading-relaxed text-ink-2">
          <li>V6 (or any CUDA/OpenACC backend) on any GPU other than the recorded Kaggle Tesla T4 — and on this Mac, which has no CUDA device.</li>
          <li>The ten-seed validation (30 runs) was executed with the V0 CPU reference only; V6 was not re-run for those seeds.</li>
          <li>V1–V4 on the external Bengaluru population: they are verified against V0 in the synthetic benchmark workload, but are not exposed by the <code className="rounded bg-surface-3 px-1 font-mono text-[11px]">extpop_run</code> executable and are therefore not available in the Simulation Studio.</li>
          <li>V7/V8 (MPI) do not exist.</li>
        </ul>
      </Card>
    </div>
  )
}
