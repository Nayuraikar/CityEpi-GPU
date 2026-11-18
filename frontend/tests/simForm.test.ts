// Run: cd frontend && node --experimental-transform-types --test tests/simForm.test.ts
import test from 'node:test'
import assert from 'node:assert/strict'
import { checkForm, toRequest, wallSeconds, isTerminal } from '../src/api/sim.ts'
import type { FormValues } from '../src/api/sim.ts'

const limits: Record<string, [number, number]> = { days: [1, 1000], seed: [0, 2 ** 53 - 1], initial_infected: [0, 10_000_000], beta: [0, 100], incubation_days: [1, 365], infectious_days: [1, 365] }
const ok: FormValues = { days: '100', seed: '42', initial_infected: '100', beta_home: '0.3', beta_work: '0.3', incubation_days: '3', infectious_days: '5' }

test('defaults are valid', () => assert.deepEqual(checkForm(ok, limits, 100000), {}))
test('rejects blanks, non-numbers and fractions in integer fields', () => {
  const e = checkForm({ ...ok, days: '', seed: 'abc', initial_infected: '1.5' }, limits, 100000)
  assert.equal(e.days, 'Enter a number'); assert.equal(e.seed, 'Enter a number'); assert.match(e.initial_infected, /whole number/)
})
test('range limits apply to both betas via the shared "beta" limit', () => {
  const e = checkForm({ ...ok, beta_home: '-1', beta_work: '101' }, limits)
  assert.ok(e.beta_home && e.beta_work)
})
test('initial infected cannot exceed the selected population', () => {
  assert.match(checkForm({ ...ok, initial_infected: '100001' }, limits, 100000).initial_infected, /cannot exceed/)
  assert.equal(checkForm({ ...ok, initial_infected: '100000' }, limits, 100000).initial_infected, undefined)
})
test('snapshot runs are limited in days only when snapshots are on', () => {
  assert.match(checkForm({ ...ok, days: '401' }, limits, 100000, 400).days, /limited to 400/)
  assert.equal(checkForm({ ...ok, days: '401' }, limits, 100000).days, undefined)
})
test('toRequest converts to numbers and only sends snapshots when asked', () => {
  const r = toRequest('ds', 'v0', ok); assert.equal(r.days, 100); assert.equal(r.beta_home, 0.3); assert.equal('snapshots' in r, false)
  assert.equal(toRequest('ds', 'v0', ok, true).snapshots, true)
})
test('wallSeconds / isTerminal', () => {
  assert.equal(wallSeconds(null, null), null)
  assert.equal(wallSeconds('2026-01-01T00:00:00Z', '2026-01-01T00:00:02.5Z'), 2.5)
  assert.ok(isTerminal('failed') && !isTerminal('running'))
})
