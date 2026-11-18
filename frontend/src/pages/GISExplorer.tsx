import { useEffect, useMemo, useRef, useState } from 'react'
import L from 'leaflet'
import { Layers as LayersIcon, Loader2, LocateFixed } from 'lucide-react'
import { getJSON, useApi } from '../api/client'
import { Card, ErrorState, Experimental, Notice, PageHeader, PageSkeleton, Source, Switch } from '../components/ui'
import { DrawLayer } from '../lib/drawLayer'
import { CAT_COLORS, catLabel, nf } from '../lib/format'
import { C } from '../lib/theme'

interface Catalog { counts: Record<string, number>; bounds: [number, number, number, number]; boundary_props: Record<string, any> }
interface Pts { columns: string[]; rows: any[][]; count: number }
interface Dens { cell_deg: number; cells: [number, number, number][]; max: number; total: number }

const ROAD_STYLE: Record<string, [string, number]> = {
  motorway: [C.coral, 3], trunk: [C.coral, 3], primary: [C.amber, 2.5], secondary: ['#c9b25a', 2], tertiary: ['#8aa0b6', 1.5],
}
const BLDG: Record<string, string> = {
  apartments: C.teal, house: C.teal, residential: C.teal, detached: C.teal, commercial: C.terracotta, retail: C.terracotta,
  industrial: C.lavender, school: C.glacier, hospital: C.coral, office: C.amber,
}

type LayerId = 'buildings' | 'roads' | 'leisure' | 'landuse' | 'healthcare' | 'destinations' | 'homes_occupied' | 'amenities'
const LAYERS: { id: LayerId; label: string; color: string; note: string; synthetic?: boolean }[] = [
  { id: 'buildings', label: 'Buildings (OSM)', color: C.glacier, note: 'density < z15, footprints ≥ z15' },
  { id: 'roads', label: 'Roads (OSM)', color: C.amber, note: 'class-filtered by zoom' },
  { id: 'landuse', label: 'Land use (OSM)', color: C.slate, note: 'zoom ≥ 12' },
  { id: 'leisure', label: 'Leisure areas (OSM)', color: C.sage, note: 'zoom ≥ 13' },
  { id: 'healthcare', label: 'Healthcare (OSM)', color: C.coral, note: 'all facilities' },
  { id: 'amenities', label: 'Amenities (OSM)', color: C.lavender, note: 'POI points' },
  { id: 'destinations', label: 'Synthetic destinations', color: C.terracotta, note: 'placeholder destinations · by category', synthetic: true },
  { id: 'homes_occupied', label: 'Occupied candidate homes', color: C.teal, note: 'OSM buildings that received synthetic residents', synthetic: true },
]

// density ramp on a light canvas: pale glacier → teal → deep navy
function ramp(t: number) {
  const a = [214, 229, 240], b = [47, 154, 147], c = [23, 45, 74]
  const u = t < 0.55 ? t / 0.55 : (t - 0.55) / 0.45, from = t < 0.55 ? a : b, to = t < 0.55 ? b : c
  return `rgb(${from.map((f, i) => Math.round(f + (to[i] - f) * u)).join(',')})`
}

export default function GISExplorer() {
  const cat = useApi<Catalog>('/api/geo/catalog')
  return (
    <>
      <PageHeader subtitle="Real OpenStreetMap-derived layers (blue-labelled) and the synthetic population's locations (amber-labelled) for Bengaluru Urban. Large layers are served by the backend per viewport." />
      {cat.loading && <PageSkeleton />}
      {cat.error && <ErrorState error={cat.error} onRetry={cat.reload} />}
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
  const [ptsErr, setPtsErr] = useState<Record<string, string>>({})
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
      // React StrictMode mounts, tears down (map.remove()) and re-mounts this effect in development. The first map is already
      // removed when this response arrives, so adding a layer to it throws "Cannot read properties of undefined (reading
      // 'appendChild')". Only the live map may receive the layer.
      if (mapRef.current !== map) return
      L.geoJSON(g, { pane: 'p-bound', interactive: false, style: { color: C.tealDeep, weight: 2, fillColor: C.teal, fillOpacity: 0.04, dashArray: '6 4' } }).addTo(map)
    }).catch(() => { /* boundary outline is decoration; every other layer still works */ })
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
    if (tiles && !tileRef.current) tileRef.current = L.tileLayer('https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png', { attribution: '© OpenStreetMap contributors © CARTO', subdomains: 'abcd', maxZoom: 19 })
    if (tileRef.current) { tiles ? tileRef.current.addTo(map).bringToBack() : map.removeLayer(tileRef.current) }
  }, [tiles])

  // --- points data (loaded once per layer when enabled)
  useEffect(() => {
    for (const id of ['healthcare', 'amenities', 'destinations', 'homes_occupied'] as LayerId[]) {
      if (on[id] && !pts[id] && !ptsErr[id]) getJSON<Pts>(`/api/geo/points/${id}`).then((d) => setPts((p) => ({ ...p, [id]: d })), (e) => setPtsErr((p) => ({ ...p, [id]: String(e.message ?? e) })))
    }
  }, [on, pts, ptsErr])

  // --- point layers
  const colorFor = useMemo(() => ({
    healthcare: () => C.coral, amenities: () => C.lavender, homes_occupied: () => C.teal,
    destinations: (cat: string) => CAT_COLORS[cat] ?? C.terracotta,
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
          if (id === 'destinations') return `<b>${nm}</b><br/>${catLabel(best[ci.category])} · synthetic destination<br/>${best[ci.occupancy]} / ${best[ci.capacity]} synthetic agents (placeholder capacity)`
          if (id === 'homes_occupied') return `<b>Candidate home #${best[ci.location_id]}</b><br/>${best[ci.occupancy]} synthetic agents assigned<br/><i>not a surveyed household</i>`
          return `<b>${nm}</b><br/>${best[ci.kind] ?? ''} · OSM`
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
        layers.current[key] = L.geoJSON(g, { pane, renderer: ((renderers.current[pane] as any)?._map === map ? renderers.current[pane] : (renderers.current[pane] = L.canvas({ pane }))), interactive: false, style: (f: any) => style(f!.properties) } as any).addTo(map)
        setSt(id, g.total_in_view === 0 ? 'none in this view' : `${nf(g.features.length)} of ${nf(g.total_in_view)} in view${g.truncated ? ' (even subsample)' : ''}`)
      }).catch((e) => { if (!ac.signal.aborted) setSt(id, `could not load (${String(e.message ?? e).slice(0, 40)})`) })
    }
    vec('roads', 9, (p) => { const [c, w] = ROAD_STYLE[p.kind] ?? ['#a3b1bf', 1]; return { color: c, weight: w, opacity: 0.85 } }, 'p-road', 9000)
    vec('buildings', 15, (p) => ({ color: BLDG[p.kind] ?? C.glacier, weight: 0.6, fillColor: BLDG[p.kind] ?? C.glacier, fillOpacity: 0.4 }), 'p-bldg', 7000)
    vec('landuse', 12, (p) => ({ color: C.slate, weight: 0.5, fillColor: C.slate, fillOpacity: 0.14 }), 'p-area', 4000)
    vec('leisure', 13, () => ({ color: C.sage, weight: 0.7, fillColor: C.sage, fillOpacity: 0.35 }), 'p-area', 4000)

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
      }, (e) => setSt('buildings', `could not load density grid (${String(e.message ?? e).slice(0, 40)})`))
    } else if (layers.current[dKey]) clear(dKey)
    return () => ctl.forEach((c) => c.abort())
  }, [on, view])

  const resetView = () => { const [s, w, n, e] = cat.bounds; mapRef.current?.fitBounds([[s, w], [n, e]], { padding: [10, 10] }) }
  const toggle = (id: LayerId) => setOn((o) => ({ ...o, [id]: !o[id] }))
  const dens = on.buildings && (view?.zoom ?? 0) < 15

  const loadingPts = (['healthcare', 'amenities', 'destinations', 'homes_occupied'] as LayerId[]).some((id) => on[id] && !pts[id])
  const group = (synthetic: boolean) => LAYERS.filter((l) => !!l.synthetic === synthetic)
  const row = (l: (typeof LAYERS)[number]) => (
    <li key={l.id} className="flex items-start gap-3 rounded-lg px-2 py-2 transition-colors hover:bg-surface-2">
      <span className="mt-1 h-2.5 w-2.5 shrink-0 rounded-sm" style={{ background: l.color, opacity: on[l.id] ? 1 : 0.35 }} />
      <span className="min-w-0 flex-1">
        <span className="flex items-center justify-between gap-2 text-sm font-medium"><span className={on[l.id] ? '' : 'text-mute'}>{l.label}</span><span className="num text-xs font-normal text-mute">{nf(cat.counts[l.id])}</span></span>
        <span className="block text-[11px] leading-snug text-mute">{ptsErr[l.id] ? <span className="text-coral-deep">could not load: {ptsErr[l.id]}</span> : status[l.id] || l.note}</span>
      </span>
      <Switch on={on[l.id]} onChange={() => toggle(l.id)} label={`Toggle ${l.label}`} />
    </li>
  )

  return (
    <div className="grid gap-4 xl:grid-cols-[1fr,340px]">
      <div className="card relative isolate overflow-hidden" style={{ height: 'min(78vh, 780px)', minHeight: 460 }}>
        <div ref={el} className="h-full w-full" role="application" data-testid="gis-map"
          aria-label="Interactive map of Bengaluru Urban. Focus the map, then use the arrow keys to pan and the plus and minus keys to zoom. Layers are switched in the Layers panel."
          aria-describedby="gis-map-summary" />
        <p id="gis-map-summary" role="status" className="sr-only">
          Layers shown: {(Object.keys(on) as LayerId[]).filter((k) => on[k]).join(', ') || 'none'}. Zoom level {view?.zoom ?? 'loading'}.
        </p>
        <div className="pointer-events-none absolute bottom-3 left-3 z-[900] rounded-lg border border-line bg-surface/90 px-2.5 py-1.5 text-[11px] text-mute shadow-card backdrop-blur">
          zoom <span className="num font-medium text-ink">{view?.zoom ?? '–'}</span> · {cat.boundary_props.name} (OSM relation {cat.boundary_props.osm_id})
        </div>
        {loadingPts && <div className="pointer-events-none absolute left-3 top-3 z-[900] flex items-center gap-1.5 rounded-lg border border-line bg-surface/90 px-2.5 py-1.5 text-[11px] text-mute shadow-card backdrop-blur"><Loader2 size={12} className="animate-spin text-teal-600" /> Loading points…</div>}
        {dens && (
          <div className="pointer-events-none absolute bottom-3 right-3 z-[900] flex items-center gap-2 rounded-lg border border-line bg-surface/90 px-2.5 py-1.5 text-[11px] text-mute shadow-card backdrop-blur">
            few <div className="h-2 w-24 rounded" style={{ background: `linear-gradient(90deg, ${ramp(0)}, ${ramp(0.55)}, ${ramp(1)})` }} /> many <span>(log, buildings/cell)</span>
          </div>
        )}
        <button onClick={resetView} aria-label="Reset view to Bengaluru Urban" title="Reset view" className="btn absolute right-3 top-14 z-[900] !p-2 xl:top-3"><LocateFixed size={16} /></button>
        <button onClick={() => setPanel(!panel)} aria-label="Toggle layer panel" aria-pressed={panel} className="btn absolute right-3 top-3 z-[900] !p-2 xl:hidden"><LayersIcon size={16} /></button>
      </div>

      <div className={`space-y-4 ${panel ? '' : 'hidden xl:block'}`}>
        <Card title="Layers" sub="Counts from the recorded bundle">
          <div className="mb-1 flex items-center justify-between px-2"><span className="label">Real data</span><Source kind="osm" /></div>
          <ul>{group(false).map(row)}</ul>
          <div className="mb-1 mt-3 flex items-center justify-between px-2"><span className="label">Synthetic population</span><Source kind="synthetic" /></div>
          <ul>{group(true).map(row)}</ul>
          <div className="mt-3 flex items-start gap-3 border-t border-line px-2 pt-3 text-xs text-mute">
            <span className="min-w-0 flex-1">Show online basemap (CARTO light, requests tiles from the internet)</span>
            <Switch on={tiles} onChange={() => setTiles(!tiles)} label="Toggle online basemap" />
          </div>
        </Card>
        {on.destinations && (
          <Card title="Destination categories" right={<Experimental>Synthetic</Experimental>}>
            <div className="grid grid-cols-1 gap-0.5">
              {Object.entries(CAT_COLORS).map(([c, col]) => (
                <button key={c} onClick={() => setCats({ ...cats, [c]: !cats[c] })} aria-pressed={cats[c]} className="flex items-center gap-2.5 rounded-lg px-2 py-1.5 text-left text-xs transition-colors hover:bg-surface-2">
                  <span className="h-3 w-3 rounded-full border-2 transition" style={{ borderColor: col, background: cats[c] ? col : 'transparent' }} />
                  <span className={cats[c] ? 'text-ink' : 'text-mute line-through'}>{catLabel(c)}</span>
                </button>
              ))}
            </div>
          </Card>
        )}
        <Card title="Legend" sub="What the colours on the map mean">
          <div className="space-y-3 text-xs text-ink-2">
            <div className="flex items-center gap-2"><span className="h-0 w-6 border-t-2 border-dashed" style={{ borderColor: C.tealDeep }} />Bengaluru Urban boundary (OSM relation)</div>
            <div>
              <div className="label mb-1">Roads (OSM highway class)</div>
              <div className="flex flex-wrap gap-x-3 gap-y-1">{Object.entries(ROAD_STYLE).map(([k, [c, w]]) => <span key={k} className="inline-flex items-center gap-1.5"><span className="w-5 rounded-full" style={{ background: c, height: w }} />{k}</span>)}<span className="inline-flex items-center gap-1.5"><span className="h-px w-5" style={{ background: '#a3b1bf' }} />other (zoom ≥ 15)</span></div>
            </div>
            <div>
              <div className="label mb-1">Building footprints (OSM <code>building</code> tag, zoom ≥ 15)</div>
              <div className="flex flex-wrap gap-x-3 gap-y-1">{[['residential types', C.teal], ['commercial / retail', C.terracotta], ['industrial', C.lavender], ['school', C.glacier], ['hospital', C.coral], ['office', C.amber], ['other / unclassified', C.glacier]].map(([k, c]) => <span key={k} className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm opacity-60" style={{ background: c }} />{k}</span>)}</div>
              <p className="mt-1 text-[11px] text-mute">Below zoom 15 buildings are shown as a density grid instead.</p>
            </div>
            <div className="flex flex-wrap gap-x-3 gap-y-1"><span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full" style={{ background: C.coral }} />healthcare (OSM)</span><span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full" style={{ background: C.lavender }} />amenity (OSM)</span><span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm" style={{ background: C.sage }} />leisure area (OSM)</span><span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm" style={{ background: C.slate }} />land use (OSM)</span></div>
            <div className="border-t border-line pt-2">
              <div className="mb-1 flex items-center justify-between"><span className="label">Synthetic</span><Source kind="synthetic" /></div>
              <div className="flex flex-wrap gap-x-3 gap-y-1"><span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full" style={{ background: C.teal }} />occupied candidate home</span>{Object.entries(CAT_COLORS).map(([c, col]) => <span key={c} className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full" style={{ background: col }} />{catLabel(c)}</span>)}</div>
            </div>
          </div>
        </Card>
        <Notice>Blue-labelled layers are real OpenStreetMap extracts. Amber-labelled layers belong to a <b>synthetic</b> population: destinations and capacities are placeholders derived from OSM tags and footprints, and an “occupied home” is an OSM building that was assigned synthetic agents — not a surveyed household. Synthetic agents do not represent actual Bengaluru residents. Hover points at zoom ≥ 14 for details. Zoom changes what is drawn: roads thin out below zoom 15, buildings are a density grid below zoom 15 and footprints above.</Notice>
      </div>
    </div>
  )
}
