# Kaggle CUDA workflow (fresh GPU validation)

The MacBook Air M1 cannot run CUDA. Everything GPU-related in the dashboard is **recorded** from earlier Kaggle Tesla T4 runs
(`ui_data_bundle/bench/results/kaggle_v5/`, `kaggle_v6/`; `bench/results/kaggle_v4/`). A fresh validation is **optional**: the
existing evidence is complete (`V6 OK`, 4212 comparisons). Use this workflow only if you want to re-confirm it, e.g. after changing
V4–V6 sources. **This workflow was not executed during the Phase 5 documentation pass.**

Rule: never write new results into the existing result directories. Use a new output directory per run (below: `OUT`).

## 1. Notebook setup

1. New Kaggle notebook → Settings → Accelerator **GPU T4 x2** (or P100), Internet **On**.
2. Add the repository as a Dataset (zip of this repo without `build*`, `node_modules`, `.venv`) or `git clone` it if it is public.
3. First cell:
   ```bash
   !nvidia-smi && nvcc --version && cmake --version
   ```
   Record the output; it is part of the evidence.

## 2. Build and test V5 + V6 (and the external-population path)

```bash
%cd /kaggle/working/CityEpi-GPU
!cmake -S . -B build-cuda -DENABLE_CUDA=ON -DENABLE_CUDA_V6=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=75
!cmake --build build-cuda -j
OUT=/kaggle/working/revalidation   # new directory
!mkdir -p $OUT
!build-cuda/test_v6 --require-gpu | tee $OUT/test_v6.log
!ctest --test-dir build-cuda -R "v5|v6|extpop" --output-on-failure | tee $OUT/ctest_gpu.log
```
Pass criteria: `test_v6` ends with `... V6 comparisons on Tesla T4; V6 OK` and exits 0; CTest reports 100% passed. T4 is `sm_75`; use
`-DCMAKE_CUDA_ARCHITECTURES=60` for a P100.

## 3. Benchmark (same methodology as the recorded runs)

```bash
!build-cuda/bench_v6 7 10000 100000 1000000 5000000 --scenario all --profile-csv $OUT/v6_profile_all.csv > $OUT/v6_benchmark_all.csv
!python3 bench/analyze_v6.py $OUT/v6_benchmark_all.csv | tee $OUT/v6_acceptance.txt
!cp /proc/cpuinfo $OUT/cpuinfo.txt; !nvidia-smi > $OUT/gpu_info.txt; !nvcc --version > $OUT/cuda_version.txt
```
Check: every row has `identical_v0=yes` and `identical_v5=yes`. Compare speedups **only within this new CSV**. The 1M-agent `V6_base`
behaviour is the known unexplained anomaly; if it disappears or changes, report that as a new observation — do not use it to rewrite the
old result.

## 4. Household population on the GPU (V0 vs V6 on the real CEPOP)

Upload `ui_data_bundle/data/synthetic/bengaluru_urban_N100000_seed42_households_v1/population.cepop` (read-only input), then:
```bash
!build-cuda/extpop_run --input population.cepop --backend both --days 100 --seed 42 --init 100 --expect-agents 100000 --expect-locations 238841 --json $OUT/extpop_v0_v6.json --daily-csv $OUT/daily
```
Expected (recorded): V0 and V6 final S/E/I/R 65,371 / 1,257 / 2,343 / 31,029 and identical daily checksum `b213860e1d97b2c8`.
`extpop_run` exits 0 on success, 1 on mismatch/invalid input, 2 if the requested backend is unavailable (for example V6 without a GPU).

## 5. What to bring back

`$OUT/*` (logs, CSVs, `gpu_info.txt`, `cuda_version.txt`, `cpuinfo.txt`) plus the notebook's git commit. Store them in a **new** folder
(for example `bench/results/kaggle_v6_revalidation_<date>/`); the dashboard reads only the bundle paths in `backend/app/benchmarks.py`
and `perf.py`, so adding a folder changes nothing until you deliberately point the backend at it.
