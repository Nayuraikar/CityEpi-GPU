export interface CurvePoint { day: number; S: number; E: number; I: number; R: number; incidence: number }
export interface RunSummary {
  attack_rate_pct: number; recovered_pct: number; peak_infectious: number; peak_day: number
  peak_daily_incidence: number; peak_incidence_day: number; final: Record<'S' | 'E' | 'I' | 'R', number>
}
export interface Run {
  key: string; label: string; agents: number; days: number; seed: number; initial_infected: number
  input: string; payload_crc32: string; v0_seconds: number; v6_seconds_total: number; v6_device: string
  daily_checksum: string; v0_v6_equal: boolean; curves_identical: boolean
  summary: RunSummary; curve: CurvePoint[]
}
export type Runs = Record<string, Run>
export interface SeedRow { scenario: string; seed: number; attack_rate_pct: number; peak_infectious: number; peak_day: number; peak_daily_incidence: number }
export interface SeedSummary { scenario: string; attack_mean: number; attack_sd: number; attack_min: number; attack_max: number; peak_mean: number; peak_sd: number; peak_day_mean: number; incidence_mean: number }
export interface Seeds {
  per_seed: SeedRow[]; summary: SeedSummary[]; curves: Record<string, Record<string, CurvePoint[]>>
  curve_seed_counts: Record<string, number>; n_seeds: number; seed_range: [number, number]
  v6_runs_present: Record<string, number>
}
export interface StatusItem { item: string; state: string; detail: string }
export interface Overview {
  population: { agents: number; locations: number; homes: number; destinations: number; households: number; mean_household_size: number; mean_commute_m: number; validation: { passed: boolean; n_checks: number }; legacy_validation: { passed: boolean; n_checks: number }; disclaimers: string[]; tool_version: string; cepop_crc32: string }
  configuration: any
  epidemic: Record<string, RunSummary & { label: string; v0_v6_equal: boolean }>
  ten_seed: SeedSummary[]; n_seeds: number
  run_environment: { gpu: string; verdict: string; generated_utc: string }
  status: StatusItem[]
}
export interface PopulationData {
  counts: any
  households: { count: number; mean_size: number; pmf_mean: number; assumption: string; buildings_with_households: number; histogram: { size: number; households: number; observed_share: number; configured_pmf: number }[] }
  home_occupancy: { histogram: { bucket: string; homes: number }[]; nonzero: any; unused_homes: number; total_homes: number; occupied_homes: number }
  destinations: { by_category: { category: string; destinations: number; capacity: number; occupancy: number; used: number; utilisation_pct: number }[]; occupancy_histogram: { bucket: string; destinations: number }[]; nonzero: any; unused_destinations: number; top: { location_id: number; name: string | null; category: string; occupancy: number; capacity: number }[] }
  assignment: { distance_summary_m: Record<string, number>; distance_histogram: { bin: string; agents: number }[]; distance_by_category: { category: string; count: number; mean: number; median: number; p95: number; max: number }[]; stages: { stage: number; agents: number; radius_m: number | null }[]; gini: number; destinations_at_capacity: number; destinations_used: number; top1pct_share: number; kernel: any }
  spatial_fidelity: any
  validation: { passed: boolean; n_checks: number; failed: any[] }
  disclaimers: string[]
}
export interface BenchRow {
  scenario?: string; agents: number; backend: string; opts?: string; exec_mode?: string
  kernel_median_s: number; kernel_min_s: number; kernel_max_s: number; kernel_cv_pct: number
  e2e_median_s: number; e2e_cv_pct: number; h2d_median_s: number; d2h_median_s: number; events_median_s: number
  kernel_speedup_v0: number; kernel_speedup_v5?: number | null; e2e_speedup_v0: number | null
  identical?: string; identical_v0?: string; identical_v5?: string; gpu_claim?: string
}
export interface Benchmarks {
  v5: { rows: BenchRow[]; meta: Record<string, string> }
  v6: { rows: BenchRow[]; meta: Record<string, string> }
  v6_all_scenarios: { rows: BenchRow[] }
  v6_profile: { scenario: string; agents: number; backend: string; opts: string; loc_ms_median: number; step_ms_median: number; loc_pct: number }[]
  v6_profile_all: { scenario: string; agents: number; backend: string; opts: string; loc_ms_median: number; step_ms_median: number; loc_pct: number }[]
  git_commit: string | null; gpu_info_head: string[]; cuda_version: string | null
}
