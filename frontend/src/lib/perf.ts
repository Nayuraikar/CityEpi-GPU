// Types and derivations for the PAGP Performance Lab. Everything is computed from recorded benchmark rows;
// a derived value is returned as null whenever a required source field is missing (never guessed).
import type { BenchRow } from '../api/types'

export interface CsvBlock<R> { file: string; meta: Record<string, string>; rows: R[] }

export interface M1V2Row {
  agents: number; backend: string; threads: number; sched: string; reduce: string; chunk: string | number
  median_s: number; speedup_v0: number; speedup_v1: number; speedup_v2_t1: number | null; efficiency: number | null; hist_MB: number; identical: string
}
export interface M1V3Row {
  agents: number; backend: string; median_s: number; min_s: number; max_s: number; cv_pct: number
  speedup_v0: number; speedup_v1: number; identical: string
}
export interface Fp { differ: number; of: number; max_rel: string }
export interface Ident { checked: number; identical: number }
export interface Perf {
  apple_m1: { env: { v2: Record<string, string>; v3: string | null }; v2: CsvBlock<M1V2Row> | null; v3: CsvBlock<M1V3Row> | null; v3_hybrid: CsvBlock<M1V3Row> | null }
  kaggle_v4: { results: CsvBlock<BenchRow> | null; test_tail: string[] }
  kaggle_v5: { file: string; meta: Record<string, string> } | null
  kaggle_v6: { file: string; meta: Record<string, string> } | null
  correctness: {
    v2_v3_cpu_rows: { v2_csv: Ident; v3_csv: Ident; v3_hybrid_csv: Ident }
    v4: { rows: Ident; test_comparisons: number | null; test_target: string | null; fp: Fp | null }
    v5: { rows: Ident }
    v6: { rows: Ident; test_comparisons: number | null; test_device: string | null; skip_exp: string | null; fp: Fp | null; test_log: string[] }
  }
}

/** A benchmark "run" is one recorded execution of a benchmark binary on one machine. Speedups are only valid inside a run. */
export interface RunInfo { id: string; label: string; hardware: string; compiler: string; days: number | null; reps: number | null; file: string; sizes: number[]; backends: string[] }

/** Throughput in agent-days per second = agents × days / median seconds. Needs `days` from the recorded header. */
export const throughput = (agents: number, days: number | null | undefined, secs: number | null | undefined) =>
  days && secs && secs > 0 ? (agents * days) / secs : null

/** Percentage improvement of `to` over `from` (time reduction). */
export const improvement = (from: number | null | undefined, to: number | null | undefined) =>
  from && to != null && from > 0 ? (1 - to / from) * 100 : null

export const rate = (v: number | null) => (v == null ? '—' : v >= 1e9 ? `${(v / 1e9).toFixed(2)} G` : v >= 1e6 ? `${(v / 1e6).toFixed(1)} M` : `${(v / 1e3).toFixed(0)} k`)

export const first = <T,>(a: T[]) => (a.length ? a[0] : undefined)
