import { expect, test as base } from '@playwright/test'
import type { Page } from '@playwright/test'

/** Every test fails on an uncaught page error or a console error, so regressions like the StrictMode/Leaflet crash cannot hide. */
export const test = base.extend<{ problems: string[] }>({
  problems: [async ({ page }, use) => {
    const problems: string[] = []
    page.on('pageerror', (e) => problems.push(`pageerror: ${e.message.split('\n')[0]}`))
    page.on('console', (m) => { if (m.type() === 'error') problems.push(`console.error: ${m.text().slice(0, 200)}`) })
    await use(problems)
    expect(problems, 'unexpected browser errors').toEqual([])
  }, { auto: true }],
})
export { expect }

export const go = async (page: Page, hash: string) => { await page.goto(`/#${hash}`); await page.waitForLoadState('networkidle') }

/** Fails if the page is wider than the viewport (horizontal scroll). 1px tolerance for sub-pixel rounding. */
export async function expectNoHorizontalOverflow(page: Page) {
  const o = await page.evaluate(() => ({ sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth }))
  expect(o.sw, `scrollWidth ${o.sw} > clientWidth ${o.cw}`).toBeLessThanOrEqual(o.cw + 1)
}

/** Recharts paths must exist and contain no NaN (a NaN `d` attribute is how a broken series silently renders as nothing). */
export async function expectValidCharts(page: Page, min = 1) {
  const charts = page.locator('main .recharts-surface')
  await expect(charts.first()).toBeVisible()
  expect(await charts.count()).toBeGreaterThanOrEqual(min)
  const bad = await page.evaluate(() => [...document.querySelectorAll('main .recharts-surface path, main .recharts-surface rect')]
    .filter((e) => /NaN|undefined|Infinity/.test(e.getAttribute('d') ?? '') || /NaN|Infinity/.test(`${e.getAttribute('x')}${e.getAttribute('y')}${e.getAttribute('width')}${e.getAttribute('height')}`)).length)
  expect(bad, 'chart elements with NaN geometry').toBe(0)
}
