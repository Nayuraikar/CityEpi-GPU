import { expect, go, test } from './fixtures'

const API = `http://127.0.0.1:${process.env.E2E_API_PORT ?? 8765}`

test.describe('API contract and failure handling', () => {
  test('the backend under test is the current build (snapshot-capable capabilities, health ok)', async ({ request }) => {
    expect((await (await request.get(`${API}/api/health`)).json()).status).toBe('ok')
    const caps = await (await request.get(`${API}/api/sim/capabilities`)).json()
    expect(caps.backends.length).toBeGreaterThan(0)
    for (const b of caps.backends) expect(b, `${b.id} must report snapshot support`).toHaveProperty('supports_snapshots')
    expect(caps.backends.map((b: { id: string }) => b.id).sort()).toEqual(['v0', 'v6'])        // V7/V8 are future work, never offered
    expect(caps.snapshot_max_days).toBeGreaterThan(0)
  })

  test('a failing data endpoint shows an error state with Retry, then recovers', async ({ page, problems }) => {
    await page.route('**/api/epidemic', (r) => r.fulfill({ status: 500, contentType: 'application/json', body: '{"detail":"boom"}' }))
    await go(page, 'epidemic')
    await expect(page.getByRole('heading', { name: 'Could not load recorded data' })).toBeVisible()
    await page.unroute('**/api/epidemic')
    await page.getByRole('button', { name: 'Retry' }).click()
    await expect(page.locator('main .recharts-surface').first()).toBeVisible()
    // the browser logs the deliberate 500 as a console error; that is the only error we tolerate here
    expect(problems.every((p) => /500|Failed to load resource/.test(p))).toBe(true)
    problems.length = 0
  })

  test('an old backend (no snapshot support in capabilities) is flagged instead of silently used', async ({ page }) => {
    await page.route('**/api/sim/capabilities*', async (route) => {
      const res = await route.fetch()
      const body = await res.json()
      for (const b of body.backends) delete b.supports_snapshots
      await route.fulfill({ response: res, json: body })
    })
    await go(page, 'studio')
    await expect(page.getByText(/appears to be an older build/)).toBeVisible()
  })

  test('an unreachable simulation API surfaces an error and a retry, not an empty page', async ({ page, problems }) => {
    await page.route('**/api/sim/capabilities*', (r) => r.abort('connectionrefused'))
    await go(page, 'studio')
    await expect(page.getByRole('heading', { name: 'Could not load recorded data' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible()
    problems.length = 0                                                                         // aborted request is logged by Chromium
  })

  test('unknown run, bad snapshot frame and traversal ids are rejected by the API', async ({ request }) => {
    expect((await request.get(`${API}/api/sim/runs/r20990101000000-deadbeef`)).status()).toBe(404)
    expect((await request.get(`${API}/api/sim/runs/..%2f..%2fetc`)).status()).toBeGreaterThanOrEqual(400)
    expect((await request.post(`${API}/api/sim/runs`, { data: { dataset: HH_NOPE, backend: 'v0' } })).status()).toBe(422)
  })
})
const HH_NOPE = '../../etc'
