import type { Page } from '@playwright/test'
import { expect, expectNoHorizontalOverflow, go, test } from './fixtures'

const HH = 'bengaluru_urban_N100000_seed42_households_v1'

/** Fill the Studio form (household population, V0) and press Run. Fields are located by their visible label. */
async function configure(page: Page, v: { days?: string; seed?: string; infected?: string; snapshots?: boolean }) {
  await go(page, 'studio')
  await expect(page.getByRole('heading', { name: 'Configure run' })).toBeVisible()
  await page.getByLabel('Population').selectOption(HH)
  await page.getByRole('tab', { name: /^V0/ }).click()
  if (v.days) await field(page, 'Days').fill(v.days)
  if (v.seed) await field(page, 'Seed').fill(v.seed)
  if (v.infected) await field(page, 'Initial infected').fill(v.infected)
  const snap = page.getByRole('checkbox', { name: /Record per-agent snapshots/ })
  if (v.snapshots !== undefined) await (v.snapshots ? snap.check() : snap.uncheck())
}
/** The label's accessible name gains the error text when a field is invalid, so match on the label's leading text. */
const field = (page: Page, label: string) => page.locator('label').filter({ hasText: new RegExp(`^${label}`) }).locator('input')
const runButton = (page: Page) => page.getByRole('button', { name: /Run simulation|Starting/ })
const stateBadge = (page: Page, s: string) => page.getByRole('main').locator('section, div').getByText(s, { exact: true }).first()
const runStatus = (page: Page) => page.getByTestId('run-status')

async function runToCompletion(page: Page, v: Parameters<typeof configure>[1]) {
  await configure(page, v)
  await runButton(page).click()
  await expect(runStatus(page)).toContainText('is completed', { timeout: 60_000 })
}

test.describe('Simulation Studio', () => {
  test('7. form validation blocks bad input and explains why', async ({ page }) => {
    await configure(page, {})
    const run = runButton(page)
    await expect(run).toBeEnabled()

    const days = field(page, 'Days')
    await days.fill('0')
    await expect(days).toHaveAttribute('aria-invalid', 'true')
    await expect(run).toBeDisabled()
    await days.fill('1001')                                        // above the server limit of 1000
    await expect(days).toHaveAttribute('aria-invalid', 'true')
    await days.fill('abc')
    await expect(days).toHaveAttribute('aria-invalid', 'true')
    await days.fill('10')
    await expect(days).toHaveAttribute('aria-invalid', 'false')

    const infected = field(page, 'Initial infected')
    await infected.fill('100001')                                  // more than the 100,000 agents
    await expect(infected).toHaveAttribute('aria-invalid', 'true')
    await expect(run).toBeDisabled()
    await infected.fill('100')

    const beta = field(page, 'β home')
    await beta.fill('-1')
    await expect(beta).toHaveAttribute('aria-invalid', 'true')
    await beta.fill('0.3')
    await expect(run).toBeEnabled()

    // V6 is shown as unavailable here (no CUDA on this host) and the page says why instead of pretending
    const v6 = page.getByRole('tab', { name: /V6/ })
    await expect(v6).toContainText('unavailable')
    await v6.click()
    await expect(page.getByText(/no usable CUDA executable\/GPU/)).toBeVisible()
    await expect(run).toBeDisabled()
    await expect(page.getByRole('main')).toContainText(/Runs here are live, not recorded/)
  })

  test('8. a live V0 run starts, shows real progress, can be cancelled, and a full run reproduces the recorded baseline', async ({ page }) => {
    // --- long run: observe genuine progress, then cancel through the UI
    await configure(page, { days: '1000', snapshots: false })
    await runButton(page).click()
    const bar = page.getByRole('progressbar', { name: 'Simulation progress' })
    await expect(bar).toBeVisible()
    await expect(page.getByText(/^Day \d+ of 1000$/)).toBeVisible({ timeout: 30_000 })
    await expect(page.getByText('Susceptible').first()).toBeVisible()          // live S/E/I/R stat tiles
    await page.getByRole('button', { name: 'Cancel' }).click()
    await expect(runStatus(page)).toContainText('is cancelled', { timeout: 30_000 })
    await expect(page.getByText('This run was cancelled. No result files were kept.')).toBeVisible()
    await page.getByRole('button', { name: 'Delete run' }).click()
    await expect(page.getByText('No runs yet.')).toBeVisible()

    // --- the recorded configuration (100 days, seed 42, 100 initially infected) must give the recorded numbers exactly
    await runToCompletion(page, { days: '100', seed: '42', infected: '100', snapshots: false })
    const main = page.getByRole('main')
    await expect(main).toContainText('34.63%')                                    // recorded attack rate 34.629 %
    await expect(main).toContainText('2,891')                                     // recorded peak infectious
    await expect(main).toContainText('598')                                       // recorded peak daily incidence
    await expect(main).toContainText('b213860e1d97b2c8')                          // recorded daily checksum
    await expect(main.locator('.recharts-surface').first()).toBeVisible()
    await expect(page.getByRole('button', { name: /Open viewer/ })).toHaveCount(0) // no snapshots were recorded -> no viewer
  })

  test('9. a snapshot-enabled V0 run opens the Viewer, and day 100 equals the recorded S/E/I/R', async ({ page }) => {
    await runToCompletion(page, { days: '100', seed: '42', infected: '100', snapshots: true })
    await expect(page.getByText('MAP', { exact: true })).toBeVisible()           // history row marks it replayable
    await page.getByRole('button', { name: /Open viewer/ }).click()
    const viewer = page.getByTestId('viewer')
    await expect(viewer).toBeVisible()
    await expect(page.getByTestId('viewer-map')).toHaveClass(/leaflet-container/, { timeout: 30_000 })
    await expect(page.getByTestId('day-label')).toHaveText('Day 0 / 100')
    await expect(page.getByTestId('val-I')).toHaveText('100')                    // 100 initially infected
    await expect(page.getByTestId('sci-note')).toContainText('fixed home locations')
    await expect(page.getByTestId('sci-note')).toContainText('synthetic')
    await expect(viewer.getByText('Your live run · replay')).toBeVisible()

    await page.getByLabel('Day timeline').fill('100')
    await expect(page.getByTestId('day-label')).toHaveText('Day 100 / 100', { timeout: 30_000 })
    await expect(page.getByTestId('stats')).toHaveAttribute('data-day', '100')
    await expect(page.getByTestId('val-S')).toHaveText('65,371')
    await expect(page.getByTestId('val-E')).toHaveText('1,257')
    await expect(page.getByTestId('val-I')).toHaveText('2,343')
    await expect(page.getByTestId('val-R')).toHaveText('31,029')
    await expect(page.getByTestId('val-attack')).toHaveText('34.63%')
    await expect(page.getByTestId('verify')).toContainText('match the daily CSV exactly')
    await expect(page.getByTestId('render-mode')).not.toHaveText('—')

    await page.getByRole('button', { name: /Studio/ }).click()                     // back to the studio, run still listed
    await expect(page.getByRole('heading', { name: 'Run history' })).toBeVisible()
  })

  test('10. Viewer playback: play, pause, step, seek, replay, reset, keyboard and 390px layout', async ({ page }) => {
    await runToCompletion(page, { days: '30', seed: '7', infected: '100', snapshots: true })
    await page.getByRole('button', { name: /Open viewer/ }).click()
    const label = page.getByTestId('day-label')
    const dayNow = async () => Number(/Day (\d+)/.exec((await label.textContent()) ?? '')?.[1])
    await expect(label).toHaveText('Day 0 / 30', { timeout: 30_000 })

    // play advances through real frames; pause stops
    await page.getByRole('group', { name: 'Playback speed' }).getByRole('button', { name: '4×' }).click()
    await page.getByRole('button', { name: 'Play', exact: true }).click()
    await expect.poll(dayNow, { timeout: 20_000 }).toBeGreaterThan(2)
    await page.getByRole('button', { name: 'Pause', exact: true }).click()
    const paused = await dayNow()
    await page.waitForTimeout(900)
    expect(await dayNow()).toBe(paused)                                         // really paused
    await expect(page.getByTestId('stats')).toHaveAttribute('data-day', String(paused))

    // step controls
    await page.getByRole('button', { name: 'Next day' }).click()
    await expect.poll(dayNow).toBe(paused + 1)
    await page.getByRole('button', { name: 'Previous day' }).click()
    await expect.poll(dayNow).toBe(paused)
    await page.getByRole('button', { name: 'Reset to day 0' }).click()
    await expect.poll(dayNow).toBe(0)
    await expect(page.getByRole('button', { name: 'Previous day' })).toBeDisabled()

    // seek (slider) keeps the stats strip, trajectory marker and CSV cross-check in sync
    const slider = page.getByLabel('Day timeline')
    await slider.fill('15')
    await expect(label).toHaveText('Day 15 / 30')
    await expect(page.getByTestId('trajectory')).toHaveAttribute('data-day', '15')
    await expect(page.getByTestId('verify')).toContainText('Day 15: frame counts and incidence match')
    // seek by keyboard on the focused slider
    await slider.focus()
    await page.keyboard.press('ArrowRight')
    await expect.poll(dayNow).toBe(16)

    // end of run -> button becomes Replay, which restarts from day 0
    await slider.fill('30')
    await expect(label).toHaveText('Day 30 / 30')
    await expect(page.getByRole('button', { name: 'Next day' })).toBeDisabled()
    await page.getByRole('button', { name: 'Replay from day 0' }).click()
    await expect.poll(dayNow, { timeout: 15_000 }).toBeLessThan(30)
    await page.getByRole('button', { name: 'Pause', exact: true }).click()

    // view modes and chart-series toggles expose their state
    const infection = page.getByRole('button', { name: 'Active infection' })
    await infection.click()
    await expect(infection).toHaveAttribute('aria-pressed', 'true')
    const incidence = page.getByRole('button', { name: 'Incidence', exact: true })
    await incidence.click()
    await expect(incidence).toHaveAttribute('aria-pressed', 'true')

    // Space toggles play/pause from the keyboard when focus is inside the viewer but not on a button
    await page.getByTestId('stats').click()
    const before = await dayNow()
    await page.keyboard.press('Space')
    await expect(page.getByRole('button', { name: 'Pause', exact: true })).toBeVisible()
    await page.keyboard.press('Space')
    await expect(page.getByRole('button', { name: 'Play', exact: true })).toBeVisible()
    expect(await dayNow()).toBeGreaterThanOrEqual(before)

    // mobile: the viewer must not create horizontal scroll
    await page.setViewportSize({ width: 390, height: 844 })
    await expect(page.getByTestId('viewer')).toBeVisible()
    await expectNoHorizontalOverflow(page)
  })

  test('11. CSV and JSON exports download and contain the run\'s real data', async ({ page, request }) => {
    await runToCompletion(page, { days: '30', seed: '42', infected: '100', snapshots: false })
    const csvLink = page.getByRole('link', { name: 'CSV' })
    const jsonLink = page.getByRole('link', { name: 'JSON' })

    const [dlCsv] = await Promise.all([page.waitForEvent('download'), csvLink.click()])
    expect(dlCsv.suggestedFilename()).toMatch(/\.csv$/)
    const jsonHref = await jsonLink.getAttribute('href')
    const csvHref = await csvLink.getAttribute('href')
    expect(csvHref && jsonHref).toBeTruthy()

    const csv = await (await request.get(`http://127.0.0.1:${process.env.E2E_API_PORT ?? 8765}${csvHref!.replace(/^.*\/api/, '/api')}`)).text()
    const lines = csv.trim().split(/\r?\n/)
    expect(lines[0]).toBe('day,S,E,I,R,new_infections')
    expect(lines).toHaveLength(31 + 1)                                           // days 0..30 + header
    for (const l of lines.slice(1)) {                                            // population is conserved on every row
      const [, S, E, I, R] = l.split(',').map(Number)
      expect(S + E + I + R).toBe(100_000)
    }
    const [dlJson] = await Promise.all([page.waitForEvent('download'), jsonLink.click()])
    expect(dlJson.suggestedFilename()).toMatch(/\.json$/)
    const j = await (await request.get(`http://127.0.0.1:${process.env.E2E_API_PORT ?? 8765}${jsonHref!.replace(/^.*\/api/, '/api')}`)).json()
    expect(j.daily).toHaveLength(31)
    expect(j.result.attack_rate_pct).toBeGreaterThanOrEqual(0)
    expect(j.request.seed).toBe(42)
  })
})
