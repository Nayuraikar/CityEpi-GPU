import os from 'node:os'
import path from 'node:path'
import { defineConfig, devices } from '@playwright/test'

/**
 * Browser smoke tests. `npm run e2e` starts its OWN backend (uvicorn) and its OWN Vite dev server on dedicated ports,
 * so the tests can never talk to an old backend that happens to be running on :8000.
 *   - dev server (not `vite preview`) on purpose: React.StrictMode double-mounts effects only in development, which is
 *     where the Leaflet "appendChild" error used to appear.
 *   - runs are written to an isolated temp directory that is wiped before and after the suite (e2e/globalSetup.ts).
 * Set E2E_REUSE=1 to attach to servers you already started on the same ports (faster local iteration).
 */
export const API_PORT = Number(process.env.E2E_API_PORT ?? 8765)
export const WEB_PORT = Number(process.env.E2E_WEB_PORT ?? 5273)
export const RUNS_DIR = path.join(os.tmpdir(), 'cityepi-e2e-runs')
const reuse = process.env.E2E_REUSE === '1'

export default defineConfig({
  testDir: './e2e',
  timeout: 90_000,
  expect: { timeout: 15_000 },
  fullyParallel: false,
  workers: 1,                       // tests share one backend + run history; keep ordering deterministic
  retries: 0,                       // a flaky test is a bug to explain, not to retry away
  reporter: [['list']],
  globalSetup: './e2e/globalSetup.ts',
  globalTeardown: './e2e/globalTeardown.ts',
  use: { baseURL: `http://localhost:${WEB_PORT}`, trace: 'retain-on-failure', screenshot: 'only-on-failure', acceptDownloads: true },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 900 } } }],
  webServer: [
    {
      command: `../backend/.venv/bin/python -m uvicorn app.main:app --port ${API_PORT}`,
      cwd: '../backend',
      url: `http://127.0.0.1:${API_PORT}/api/health`,
      env: { CITYEPI_RUNS_DIR: RUNS_DIR },
      reuseExistingServer: reuse,
      timeout: 60_000,
    },
    {
      command: `npx vite --port ${WEB_PORT} --strictPort`,
      url: `http://localhost:${WEB_PORT}`,
      env: { CITYEPI_API: `http://127.0.0.1:${API_PORT}` },
      reuseExistingServer: reuse,
      timeout: 60_000,
    },
  ],
})
