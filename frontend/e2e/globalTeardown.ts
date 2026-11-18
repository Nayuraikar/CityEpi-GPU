import fs from 'node:fs'
import { RUNS_DIR } from '../playwright.config'

export default async function globalTeardown() {
  fs.rmSync(RUNS_DIR, { recursive: true, force: true })
}
