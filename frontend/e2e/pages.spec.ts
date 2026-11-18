import { expect, expectValidCharts, go, test } from './fixtures'

test.describe('recorded-result pages', () => {
  test('1. Overview loads with its sections, charts and the synthetic-data banner', async ({ page }) => {
    await go(page, 'overview')
    await expect(page.getByRole('heading', { level: 1, name: 'Project Overview' })).toBeVisible()
    for (const h of ['Synthetic population', 'Epidemic outcome', 'Trajectory preview', 'Project status', 'Architecture', 'Recorded results vs live simulation'])
      await expect(page.getByRole('heading', { level: 2, name: h })).toBeVisible()
    await expect(page.locator('main')).toContainText('100,000')
    await expect(page.getByRole('complementary')).toContainText('not census data')   // sidebar disclaimer
    await expectValidCharts(page)
  })

  test('2. GIS map loads, layers toggle, and keyboard users can operate the map', async ({ page }) => {
    await go(page, 'gis')
    const map = page.getByTestId('gis-map')
    await expect(map).toHaveClass(/leaflet-container/)
    await expect(page.locator('main canvas').first()).toBeAttached()
    await expect(map).toHaveAttribute('aria-label', /arrow keys/)

    // layer toggles: aria-checked flips and the screen-reader summary follows
    const summary = page.locator('#gis-map-summary')
    const roads = page.getByRole('switch', { name: 'Toggle Roads (OSM)' })
    await expect(roads).toHaveAttribute('aria-checked', 'true')
    await expect(summary).toContainText('roads')
    await roads.click()
    await expect(roads).toHaveAttribute('aria-checked', 'false')
    await expect(summary).not.toContainText('roads')
    await roads.click()
    await expect(summary).toContainText('roads')

    // synthetic layers fetch real points and show the destination-category filters
    const homes = page.getByRole('switch', { name: 'Toggle Occupied candidate homes' })
    const loaded = page.waitForResponse((r) => r.url().includes('/api/geo/points/homes_occupied') && r.ok())
    await homes.click()
    await loaded
    await expect(summary).toContainText('homes_occupied')
    await expect(page.getByRole('heading', { name: 'Destination categories' })).toBeVisible()
    const edu = page.getByRole('button', { name: 'Education' })
    await expect(edu).toHaveAttribute('aria-pressed', 'true')
    await edu.click()
    await expect(edu).toHaveAttribute('aria-pressed', 'false')

    // keyboard: focus the map, '+' zooms in (Leaflet keyboard handler), the zoom readout follows
    const readout = page.locator('main').getByText(/^zoom\s*\d+/).first()
    const zoomOf = async () => Number(/zoom\s*(\d+)/.exec((await readout.textContent()) ?? '')?.[1])
    const z0 = await zoomOf()
    await map.focus()
    await expect(map).toBeFocused()
    await page.keyboard.press('+')
    await expect.poll(zoomOf, { timeout: 8000 }).toBeGreaterThan(z0)
    await page.getByRole('button', { name: 'Reset view to Bengaluru Urban' }).click()
    await expect.poll(zoomOf, { timeout: 8000 }).toBeLessThanOrEqual(z0)
    // OSM vs synthetic provenance is stated on the page
    await expect(page.locator('main')).toContainText('not a surveyed household')
  })

  test('3. Population Explorer renders distributions with synthetic caveats', async ({ page }) => {
    await go(page, 'population')
    for (const h of ['Household-size distribution', 'Home occupancy', 'Assignment distance', 'Destination assignments by category'])
      await expect(page.getByRole('heading', { level: 2, name: h, exact: true })).toBeVisible()
    await expectValidCharts(page, 5)
    await expect(page.locator('main')).toContainText(/synthetic/i)
    await expect(page.locator('main')).toContainText(/not census|experimental/i)
  })

  test('4. Epidemic Analysis renders valid charts and every scenario tab', async ({ page }) => {
    await go(page, 'epidemic')
    await expectValidCharts(page, 3)
    for (const name of ['Legacy population (no households)', 'Household population', 'Low transmission', 'Baseline transmission', 'High transmission']) {
      const tab = page.getByRole('tab', { name })
      await tab.click()
      await expect(tab).toHaveAttribute('aria-selected', 'true')
      await expectValidCharts(page, 3)
    }
    // the recorded household baseline must still read 34.629 % (34.63 in the UI)
    await page.getByRole('tab', { name: 'Household population' }).click()
    await expect(page.locator('main')).toContainText(/34\.6/)
    await page.getByRole('tab', { name: '% of pop.' }).click()
    await expectValidCharts(page, 3)
  })

  test('5. Scenario Comparison renders legacy/household, sensitivity and ten-seed validation', async ({ page }) => {
    await go(page, 'scenarios')
    for (const h of ['Population structure: legacy vs household', 'Transmission sensitivity: low / baseline / high', 'Ten-seed validation'])
      await expect(page.getByRole('heading', { level: 2, name: h })).toBeVisible()
    await expectValidCharts(page, 6)
    for (const name of ['Daily incidence', 'Recovered', 'Infectious']) {
      const tab = page.getByRole('tab', { name }).first()
      await tab.click()
      await expect(tab).toHaveAttribute('aria-selected', 'true')
      await expectValidCharts(page, 6)
    }
  })

  test('6. PAGP Performance Lab tabs work and keep the provenance caveats visible', async ({ page }) => {
    await go(page, 'gpu')
    const tabs = ['Architecture', 'Benchmarks', 'CUDA deep dive', 'Correctness']
    for (const name of tabs) {
      const tab = page.getByRole('tab', { name })
      await tab.click()
      await expect(tab).toHaveAttribute('aria-selected', 'true')
      await expect(page.locator('main h2, main h3').first()).toBeVisible()
    }
    await page.getByRole('tab', { name: 'Benchmarks' }).click()
    await expect(page.locator('main')).toContainText(/NEON is\s+aarch64-only|NEON is aarch64-only/i)            // Kaggle V3 = scalar fallback
    await expect(page.locator('main')).toContainText(/openmp=OFF/i)                                            // OpenACC run: V2_maxT not multithreaded
    await expect(page.locator('main')).toContainText(/slower than V1/i)                                        // M1 NEON result not overclaimed
    await page.getByRole('tab', { name: 'CUDA deep dive' }).click()
    await expect(page.locator('main')).toContainText('1M-agent anomaly')
    // deep link keeps working
    await go(page, 'gpu/ok')
    await expect(page.getByRole('tab', { name: 'Correctness' })).toHaveAttribute('aria-selected', 'true')
  })
})
