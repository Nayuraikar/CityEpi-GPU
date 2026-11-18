import fs from 'node:fs'
import { RUNS_DIR } from '../playwright.config'

// Runs from earlier sessions must not leak into history assertions. (The backend marks runs it finds as 'running' failed on start.)
export default async function globalSetup() {
  fs.rmSync(RUNS_DIR, { recursive: true, force: true })
  fs.mkdirSync(RUNS_DIR, { recursive: true })
}
