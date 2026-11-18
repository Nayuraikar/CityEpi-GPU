import { expect, expectNoHorizontalOverflow, go, test } from './fixtures'

const PAGES = ['overview', 'gis', 'population', 'epidemic', 'scenarios', 'gpu', 'studio']
const VIEWPORTS = [{ name: 'desktop 1440', width: 1440, height: 900 }, { name: 'tablet 1024', width: 1024, height: 768 }, { name: 'mobile 390', width: 390, height: 844 }]

test.describe('responsive layout', () => {
  for (const vp of VIEWPORTS) {
    test(`12. no horizontal overflow on any page at ${vp.name}px`, async ({ page }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height })
      for (const p of PAGES) {
        await go(page, p)
        await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
        await page.waitForTimeout(400)                           // let charts/maps settle to their final size
        await expectNoHorizontalOverflow(page).catch((e) => { throw new Error(`${p} @ ${vp.width}px: ${e.message}`) })
      }
    })
  }

  test('mobile navigation drawer opens, navigates and closes with Escape', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await go(page, 'overview')
    await page.getByRole('button', { name: 'Open menu' }).click()
    const link = page.getByRole('navigation', { name: 'Primary' }).last().getByRole('link', { name: 'Population Explorer' })
    await expect(link).toBeVisible()
    await link.click()
    await expect(page.getByRole('heading', { level: 1, name: 'Population Explorer' })).toBeVisible()
    await page.getByRole('button', { name: 'Open menu' }).click()
    await expect(page.getByRole('button', { name: 'Close menu' })).toBeVisible()
    await page.keyboard.press('Escape')
    await expect(page.getByRole('button', { name: 'Open menu' })).toBeVisible()
  })
})

test.describe('keyboard and accessibility', () => {
  test('Tab reaches the navigation with a visible focus ring, and Enter navigates', async ({ page }) => {
    await go(page, 'overview')
    let ring = ''
    for (let i = 0; i < 6 && !ring; i++) {
      await page.keyboard.press('Tab')
      ring = await page.evaluate(() => {
        const e = document.activeElement as HTMLElement | null
        if (!e || e.tagName !== 'A') return ''
        const c = getComputedStyle(e)
        return c.outlineStyle !== 'none' && parseFloat(c.outlineWidth) >= 2 ? `${e.textContent?.trim()}|${c.outlineWidth}` : ''
      })
    }
    expect(ring, 'a nav link should be focused with a >=2px outline').not.toBe('')
    const gis = page.getByRole('navigation', { name: 'Primary' }).first().getByRole('link', { name: 'GIS Explorer' })
    await gis.focus()
    await page.keyboard.press('Enter')
    await expect(page.getByRole('heading', { level: 1, name: 'Bengaluru GIS Explorer' })).toBeVisible()
    await expect(gis).toHaveAttribute('aria-current', 'page')
  })

  test('tabs and toggles expose state; every control has an accessible name', async ({ page }) => {
    for (const p of PAGES) {
      await go(page, p)
      await page.waitForTimeout(300)
      const unnamed = await page.evaluate(() => {
        const name = (e: Element) => {
          const h = e as HTMLInputElement
          if (e.getAttribute('aria-label') || e.getAttribute('aria-labelledby') || e.getAttribute('title')) return true
          if ((e.textContent ?? '').trim()) return true
          if (h.labels && h.labels.length) return true
          return false
        }
        return [...document.querySelectorAll('button, a[href], input, select, textarea, [role=tab], [role=switch]')]
          .filter((e) => !name(e) && (e as HTMLElement).offsetParent !== null).map((e) => e.outerHTML.slice(0, 100))
      })
      expect(unnamed, `${p}: controls without an accessible name`).toEqual([])
    }
    await go(page, 'gis')
    for (const sw of await page.getByRole('switch').all()) await expect(sw).toHaveAttribute('aria-checked', /true|false/)
    await go(page, 'epidemic')
    for (const t of await page.getByRole('tab').all()) await expect(t).toHaveAttribute('aria-selected', /true|false/)
  })

  test('the Performance Lab tab strip is keyboard operable', async ({ page }) => {
    await go(page, 'gpu')
    const bench = page.getByRole('tab', { name: 'Benchmarks' })
    await bench.focus()
    await page.keyboard.press('Enter')
    await expect(bench).toHaveAttribute('aria-selected', 'true')
  })

  test('repeated navigation between all pages stays error-free and keeps memory bounded', async ({ page }) => {
    await go(page, 'overview')
    const heap = () => page.evaluate(() => (performance as unknown as { memory?: { usedJSHeapSize: number } }).memory?.usedJSHeapSize ?? 0)
    for (const p of PAGES) { await page.goto(`/#${p}`); await page.waitForTimeout(500) }       // warm up
    const h0 = await heap()
    for (let round = 0; round < 3; round++) for (const p of PAGES) { await page.goto(`/#${p}`); await page.waitForTimeout(250) }
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
    const h1 = await heap()
    // Not a leak proof, a tripwire: 21 more navigations must not triple the JS heap (Leaflet maps are removed on unmount).
    if (h0 > 0) expect(h1, `JS heap grew ${(h0 / 2 ** 20).toFixed(1)} -> ${(h1 / 2 ** 20).toFixed(1)} MiB`).toBeLessThan(h0 * 3)
    expect(await page.locator('.leaflet-container').count()).toBeLessThanOrEqual(1)             // no orphaned maps
  })
})
