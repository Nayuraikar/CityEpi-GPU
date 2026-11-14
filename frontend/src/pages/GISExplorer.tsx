import { useEffect, useMemo, useRef, useState } from 'react'
import L from 'leaflet'
import { Layers as LayersIcon } from 'lucide-react'
import { getJSON, useApi } from '../api/client'
import { Card, Experimental, Notice, PageHeader } from '../components/ui'
import { DrawLayer } from '../lib/drawLayer'
import { CAT_COLORS, catLabel, nf } from '../lib/format'

interface Catalog { counts: Record<string, number>; bounds: [number, number, number, number]; boundary_props: Record<string, any> }
interface Pts { columns: string[]; rows: any[][]; count: number }
interface Dens { cell_deg: number; cells: [number, number, number][]; max: number; total: number }

const ROAD_STYLE: Record<string, [string, number]> = {
  motorway: ['#ff8a5c', 3], trunk: ['#ff8a5c', 3], primary: ['#f5b83d', 2.5], secondary: ['#e9d36a', 2], tertiary: ['#9fb7e8', 1.5],
}
const BLDG: Record<string, string> = {
  apartments: '#5eead4', house: '#5eead4', residential: '#5eead4', detached: '#5eead4', commercial: '#fb923c', retail: '#fb923c',
  industrial: '#a78bfa', school: '#4da3ff', hospital: '#ff5d6c', office: '#f5b83d',
}

type LayerId = 'buildings' | 'roads' | 'leisure' | 'landuse' | 'healthcare' | 'destinations' | 'homes_occupied' | 'amenities'
const LAYERS: { id: LayerId; label: string; color: string; note: string }[] = [
  { id: 'buildings', label: 'Buildings (OSM)', color: '#7aa2d8', note: 'density < z15, footprints ≥ z15' },
  { id: 'roads', label: 'Roads (OSM)', color: '#f5b83d', note: 'class-filtered by zoom' },
  { id: 'landuse', label: 'Land use (OSM)', color: '#6b7aa5', note: 'zoom ≥ 12' },
  { id: 'leisure', label: 'Leisure areas (OSM)', color: '#4ad6a0', note: 'zoom ≥ 13' },
  { id: 'healthcare', label: 'Healthcare (OSM)', color: '#ff5d6c', note: 'all facilities' },
  { id: 'amenities', label: 'Amenities (OSM)', color: '#c084fc', note: 'POI points' },
  { id: 'destinations', label: 'Activity destinations', color: '#fb923c', note: 'synthetic · by category' },
  { id: 'homes_occupied', label: 'Occupied homes', color: '#5eead4', note: 'synthetic households' },
]

function ramp(t: number) {
  const a = [18, 51, 92], b = [94, 234, 212], c = [255, 247, 205]
  const u = t < 0.6 ? t / 0.6 : (t - 0.6) / 0.4, from = t < 0.6 ? a : b, to = t < 0.6 ? b : c
  return `rgb(${from.map((f, i) => Math.round(f + (to[i] - f) * u)).join(',')})`
}

export default function GISExplorer() {
  const cat = useApi<Catalog>('/api/geo/catalog')
  return (
    <>
      <PageHeader title="Bengaluru GIS Explorer" subtitle="Actual Bengaluru Urban boundary, OpenStreetMap-derived layers and the synthetic population's locations. Large layers are served by the backend per viewport." />
      {cat.error && <Notice>Could not load catalog: {cat.error}. Is the FastAPI backend running on port 8000?</Notice>}
      {cat.data && <MapView cat={cat.data} />}
    </>
  )
}

function MapView({ cat }: { cat: Catalog }) {
  const el = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | undefined>(undefined)
  const layers = useRef<Record<string, L.Layer>>({})
  const [on, setOn] = useState<Record<LayerId, boolean>>({ buildings: true, roads: true, landuse: false, leisure: false, healthcare: true, amenities: false, destinations: true, homes_occupied: false })
  const [cats, setCats] = useState<Record<string, boolean>>(() => Object.fromEntries(Object.keys(CAT_COLORS).map((c) => [c, true])))
  const [tiles, setTiles] = useState(false)
  const [view, setView] = useState<{ bbox: string; zoom: number } | null>(null)
  const [status, setStatus] = useState<Record<string, string>>({})
  const [pts, setPts] = useState<Record<string, Pts>>({})
  const [panel, setPanel] = useState(true)
  const renderers = useRef<Record<string, L.Canvas>>({})
  const tileRef = useRef<L.TileLayer | undefined>(undefined)

  // --- map init
  useEffect(() => {
    const map = L.map(el.current!, { preferCanvas: true, zoomControl: true, minZoom: 9, maxZoom: 19, zoomSnap: 0.5 })
    const [s, w, n, e] = cat.bounds
    const q = new URLSearchParams(location.search)
    if (q.get('lat') && q.get('lng')) map.setView([+q.get('lat')!, +q.get('lng')!], +(q.get('z') ?? 15))
    else map.fitBounds([[s, w], [n, e]], { padding: [10, 10] })
    mapRef.current = map
    ;['p-area:405', 'p-bldg:410', 'p-road:420', 'p-pts:450', 'p-bound:460'].forEach((p) => { const [name, z] = p.split(':'); map.createPane(name).style.zIndex = z })
    map.getPane('p-bound')!.style.pointerEvents = 'none'
    getJSON<any>('/api/geo/boundary').then((g) => {
      L.geoJSON(g, { pane: 'p-bound', interactive: false, style: { color: '#5eead4', weight: 2, fillColor: '#5eead4', fillOpacity: 0.03, dashArray: '6 4' } }).addTo(map)
    })
    const upd = () => { const b = map.getBounds(); setView({ bbox: [b.getWest(), b.getSouth(), b.getEast(), b.getNorth()].map((v) => v.toFixed(5)).join(','), zoom: Math.floor(map.getZoom()) }) }
    let t: number
    map.on('moveend', () => { clearTimeout(t); t = window.setTimeout(upd, 250) })
    upd()

    const tip = L.tooltip({ sticky: false, direction: 'top', offset: [0, -6] })
    map.on('mousemove', (ev: L.LeafletMouseEvent) => {
      for (const id of ['homes_occupied', 'destinations', 'healthcare', 'amenities']) {
        const l = layers.current[id] as DrawLayer | undefined
        if (l && map.hasLayer(l)) {
          const h = l.hit(ev.containerPoint)
          if (h) { tip.setLatLng(ev.latlng).setContent(h).addTo(map); return }
        }
      }
      map.removeLayer(tip)
    })
    return () => { renderers.current = {}; layers.current = {}; mapRef.current = undefined; map.remove() }
  }, [cat])

  // --- basemap toggle (optional, online)
  useEffect(() => {
    const map = mapRef.current; if (!map) return
    if (tiles && !tileRef.current) tileRef.current = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png', { attribution: '© OpenStreetMap contributors © CARTO', subdomains: 'abcd', maxZoom: 19 })
    if (tileRef.current) { tiles ? tileRef.current.addTo(map).bringToBack() : map.removeLayer(tileRef.current) }
  }, [tiles])

  // --- points data (loaded once per layer when enabled)
  useEffect(() => {
    for (const id of ['healthcare', 'amenities', 'destinations', 'homes_occupied'] as LayerId[]) {
      if (on[id] && !pts[id]) getJSON<Pts>(`/api/geo/points/${id}`).then((d) => setPts((p) => ({ ...p, [id]: d })))
    }
  }, [on, pts])

  // --- point layers
  const colorFor = useMemo(() => ({
    healthcare: () => '#ff5d6c', amenities: () => '#c084fc', homes_occupied: () => '#5eead4',
    destinations: (cat: string) => CAT_COLORS[cat] ?? '#fb923c',
  } as Record<string, (c: string) => string>), [])
  useEffect(() => {
    const map = mapRef.current; if (!map) return
    for (const id of ['healthcare', 'amenities', 'destinations', 'homes_occupied'] as LayerId[]) {
      const data = pts[id]; if (!data) continue
      const ci = Object.fromEntries(data.columns.map((c, i) => [c, i]))
      const visible = (r: any[]) => id !== 'destinations' || cats[r[ci.category]]
      const radius = (z: number) => id === 'homes_occupied' ? (z < 13 ? 0.8 : z < 16 ? 1.6 : 3) : id === 'destinations' ? (z < 13 ? 1.4 : z < 16 ? 2.4 : 4) : (z < 13 ? 1.6 : z < 16 ? 2.8 : 4.5)
      const spec = {
        draw: (ctx: CanvasRenderingContext2D, m: L.Map) => {
          const b = m.getBounds().pad(0.05), r = radius(m.getZoom())
          ctx.globalAlpha = id === 'homes_occupied' ? 0.7 : 0.9
          for (const row of data.rows) {
            const lon = row[ci.lon], lat = row[ci.lat]
            if (lat < b.getSouth() || lat > b.getNorth() || lon < b.getWest() || lon > b.getEast() || !visible(row)) continue
            const p = m.latLngToContainerPoint([lat, lon])
            ctx.fillStyle = colorFor[id](row[ci.category] ?? '')
            ctx.beginPath(); ctx.arc(p.x, p.y, r, 0, 6.2832); ctx.fill()
          }
        },
        hit: (pt: L.Point, m: L.Map) => {
          if (m.getZoom() < 14) return null
          let best: any[] | null = null, bd = 8
          for (const row of data.rows) {
            if (!visible(row)) continue
            const p = m.latLngToContainerPoint([row[ci.lat], row[ci.lon]])
            const d = Math.hypot(p.x - pt.x, p.y - pt.y)
            if (d < bd) { bd = d; best = row }
          }
          if (!best) return null
          const nm = best[ci.name] || '(unnamed)'
          if (id === 'destinations') return `<b>${nm}</b><br/>${catLabel(best[ci.category])}<br/>${best[ci.occupancy]} / ${best[ci.capacity]} agents`
          if (id === 'homes_occupied') return `<b>Home #${best[ci.location_id]}</b><br/>${best[ci.occupancy]} residents (synthetic)`
          return `<b>${nm}</b><br/>${best[ci.kind] ?? ''}`
        },
      }
      const existing = layers.current[id] as DrawLayer | undefined
      if (existing) existing.setSpec(spec)
      else layers.current[id] = new DrawLayer(spec, 'p-pts')
    }
  }, [pts, cats, colorFor])
  useEffect(() => {
    const map = mapRef.current; if (!map) return
    for (const id of ['healthcare', 'amenities', 'destinations', 'homes_occupied'] as LayerId[]) {
      const l = layers.current[id]; if (!l) continue
      if (on[id] && !map.hasLayer(l)) l.addTo(map)
      if (!on[id] && map.hasLayer(l)) map.removeLayer(l)
    }
  }, [on, pts])

  // --- viewport-driven vector layers
  useEffect(() => {
    const map = mapRef.current; if (!map || !view) return
    const ctl: AbortController[] = []
    const setSt = (k: string, v: string) => setStatus((s) => ({ ...s, [k]: v }))
    const clear = (id: string) => { const l = layers.current[id]; if (l) { map.removeLayer(l); delete layers.current[id] } }

    const vec = (id: 'roads' | 'buildings' | 'landuse' | 'leisure', minZoom: number, style: (p: any) => L.PathOptions, pane: string, limit: number) => {
      const key = `vec-${id}`
      if (!on[id] || view.zoom < minZoom) { clear(key); setSt(id, on[id] ? `zoom in to ≥ ${minZoom}` : ''); return }
      const ac = new AbortController(); ctl.push(ac)
      fetch(`/api/geo/features/${id}?bbox=${view.bbox}&zoom=${view.zoom}&limit=${limit}`, { signal: ac.signal }).then((r) => r.json()).then((g) => {
        if (ac.signal.aborted || mapRef.current !== map || !map.getPane(pane)) return
        clear(key)
        layers.current[key] = L.geoJSON(g, { pane, renderer: renderers.current[pane] ?? (renderers.current[pane] = L.canvas({ pane })), interactive: false, style: (f: any) => style(f!.properties) } as any).addTo(map)
        setSt(id, `${nf(g.features.length)} of ${nf(g.total_in_view)} in view${g.truncated ? ' (even subsample)' : ''}`)
      }).catch(() => {})
    }
    vec('roads', 9, (p) => { const [c, w] = ROAD_STYLE[p.kind] ?? ['#4b5b80', 1]; return { color: c, weight: w, opacity: 0.85 } }, 'p-road', 9000)
    vec('buildings', 15, (p) => ({ color: BLDG[p.kind] ?? '#7aa2d8', weight: 0.6, fillColor: BLDG[p.kind] ?? '#7aa2d8', fillOpacity: 0.35 }), 'p-bldg', 7000)
    vec('landuse', 12, (p) => ({ color: '#6b7aa5', weight: 0.5, fillColor: '#6b7aa5', fillOpacity: 0.12 }), 'p-area', 4000)
    vec('leisure', 13, () => ({ color: '#4ad6a0', weight: 0.7, fillColor: '#4ad6a0', fillOpacity: 0.3 }), 'p-area', 4000)

    // building density (low zoom)
    const dKey = 'dens-buildings'
    if (on.buildings && view.zoom < 15) {
      const cell = view.zoom <= 11 ? 0.008 : view.zoom <= 13 ? 0.004 : 0.002
      getJSON<Dens>(`/api/geo/density/buildings?cell=${cell}`).then((d) => {
        if (mapRef.current !== map) return
        const spec = {
          draw: (ctx: CanvasRenderingContext2D, m: L.Map) => {
            ctx.globalAlpha = 0.85
            const lm = Math.log(d.max + 1)
            for (const [x0, y0, c] of d.cells) {
              const a = m.latLngToContainerPoint([y0, x0]), b = m.latLngToContainerPoint([y0 + d.cell_deg, x0 + d.cell_deg])
              ctx.fillStyle = ramp(Math.log(c + 1) / lm)
              ctx.fillRect(a.x, b.y, a.x === b.x ? 1 : b.x - a.x + 0.5, a.y - b.y + 0.5)
            }
          },
        }
        const ex = layers.current[dKey] as DrawLayer | undefined
        if (ex) ex.setSpec(spec); else { layers.current[dKey] = new DrawLayer(spec, 'p-bldg'); layers.current[dKey].addTo(map) }
        setSt('buildings', `density grid · ${nf(d.total)} footprints · max ${nf(d.max)}/cell`)
      })
    } else if (layers.current[dKey]) clear(dKey)
    return () => ctl.forEach((c) => c.abort())
  }, [on, view])

  const toggle = (id: LayerId) => setOn((o) => ({ ...o, [id]: !o[id] }))
  const dens = on.buildings && (view?.zoom ?? 0) < 15

  return (
    <div className="grid gap-4 xl:grid-cols-[1fr,320px]">
      <div className="card relative overflow-hidden" style={{ height: 'min(78vh, 780px)', minHeight: 460 }}>
        <div ref={el} className="h-full w-full" />
        <div className="pointer-events-none absolute bottom-3 left-3 z-[900] rounded-md bg-bg/80 px-2 py-1 text-[11px] text-mute backdrop-blur">
          zoom <span className="num text-ink">{view?.zoom ?? '–'}</span> · {cat.boundary_props.name} (OSM relation {cat.boundary_props.osm_id})
        </div>
        {dens && (
          <div className="pointer-events-none absolute bottom-3 right-3 z-[900] flex items-center gap-2 rounded-md bg-bg/80 px-2 py-1 text-[11px] text-mute backdrop-blur">
            few <div className="h-2 w-24 rounded" style={{ background: `linear-gradient(90deg, ${ramp(0)}, ${ramp(0.6)}, ${ramp(1)})` }} /> many <span>(log, buildings/cell)</span>
          </div>
        )}
        <button onClick={() => setPanel(!panel)} className="absolute right-3 top-3 z-[900] rounded-lg border border-line bg-panel/90 p-2 xl:hidden"><LayersIcon size={16} /></button>
      </div>

      <div className={`space-y-4 ${panel ? '' : 'hidden xl:block'}`}>
        <Card title="Layers" sub="Counts from the recorded bundle">
          <ul className="space-y-2">
            {LAYERS.map((l) => (
              <li key={l.id}>
                <label className="flex cursor-pointer items-start gap-2.5">
                  <input type="checkbox" checked={on[l.id]} onChange={() => toggle(l.id)} className="mt-1 accent-teal-400" />
                  <span className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-sm" style={{ background: l.color }} />
                  <span className="min-w-0 flex-1">
                    <span className="flex justify-between text-sm"><span>{l.label}</span><span className="num text-xs text-mute">{nf(cat.counts[l.id])}</span></span>
                    <span className="block text-[11px] text-mute">{status[l.id] || l.note}</span>
                  </span>
                </label>
              </li>
            ))}
          </ul>
          <label className="mt-3 flex cursor-pointer items-center gap-2 border-t border-line pt-3 text-xs text-mute">
            <input type="checkbox" checked={tiles} onChange={() => setTiles(!tiles)} className="accent-teal-400" /> Show online basemap (CARTO dark, requests tiles from the internet)
          </label>
        </Card>
        {on.destinations && (
          <Card title="Destination categories" right={<Experimental>Synthetic</Experimental>}>
            <div className="grid grid-cols-1 gap-1.5">
              {Object.entries(CAT_COLORS).map(([c, col]) => (
                <label key={c} className="flex cursor-pointer items-center gap-2 text-xs">
                  <input type="checkbox" checked={cats[c]} onChange={() => setCats({ ...cats, [c]: !cats[c] })} className="accent-teal-400" />
                  <span className="h-2.5 w-2.5 rounded-full" style={{ background: col }} /> {catLabel(c)}
                </label>
              ))}
            </div>
          </Card>
        )}
        <Notice tone="info">Boundary, buildings, roads, healthcare, amenities, leisure and land use are real OSM extracts. Destinations and homes are the synthetic population's placeholder locations (derived from OSM tags/footprints), not surveyed data. Hover points at zoom ≥ 14 for details.</Notice>
      </div>
    </div>
  )
}
