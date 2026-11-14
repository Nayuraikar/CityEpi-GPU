// Modular data layer: every dashboard dataset is fetched from the FastAPI backend (/api/*),
// which only serves files recorded in ui_data_bundle/.
import { useEffect, useState } from 'react'

const cache = new Map<string, Promise<unknown>>()

export function getJSON<T>(url: string): Promise<T> {
  if (!cache.has(url)) {
    const p = fetch(url).then(async (r) => {
      if (!r.ok) throw new Error(`${r.status} ${r.statusText} — ${url}`)
      return r.json()
    })
    p.catch(() => cache.delete(url))
    cache.set(url, p)
  }
  return cache.get(url) as Promise<T>
}

export interface Async<T> { data?: T; error?: string; loading: boolean }

export function useApi<T>(url: string | null): Async<T> {
  const [s, setS] = useState<Async<T>>({ loading: !!url })
  useEffect(() => {
    if (!url) return
    let live = true
    setS({ loading: true })
    getJSON<T>(url).then(
      (data) => live && setS({ data, loading: false }),
      (e) => live && setS({ error: String(e.message ?? e), loading: false }),
    )
    return () => { live = false }
  }, [url])
  return s
}
