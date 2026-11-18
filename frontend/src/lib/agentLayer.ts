import L from 'leaflet'
import { buildGrid, gridCounts, INDIVIDUAL_ZOOM, mixColor, Positions, prevalenceColor, STATE_RGB } from './viewerCore'
import type { Grid } from './viewerCore'

// Canvas layer that draws the agents of ONE stored frame at their fixed home coordinates.
//   zoom <  INDIVIDUAL_ZOOM : geo-anchored grid cells (counts per cell, composition or active-infection view)
//   zoom >= INDIVIDUAL_ZOOM : every agent in the viewport as a dot, batched one path per state
// Nothing is interpolated: the layer only ever paints the frame it was given.

export type ViewMode = 'composition' | 'infection'
export interface LayerStatus { mode: 'grid' | 'individual'; zoom: number; cells: number; visibleAgents: number; drawMs: number }
export type HoverInfo =
  | { kind: 'cell'; counts: [number, number, number, number]; lon: number; lat: number }
  | { kind: 'agent'; id: number; state: number; lon: number; lat: number }

const TAU = Math.PI * 2
const merc = (lat: number) => 0.5 - Math.log(Math.tan(Math.PI / 4 + (lat * Math.PI) / 360)) / TAU
const invMercLat = (y: number) => (Math.atan(Math.sinh(Math.PI * (1 - 2 * y))) * 180) / Math.PI
const dotRadius = (z: number) => (z < 15 ? 1.6 : z < 16 ? 2.2 : z < 17 ? 3 : z < 18 ? 4 : 5)

interface GridCache { grid: Grid; occupied: Int32Array; totals: Uint32Array; maxTotal: number }

export class AgentLayer extends L.Layer {
  private canvas?: HTMLCanvasElement
  private pos?: Positions
  private frame?: Uint8Array
  private mode: ViewMode = 'composition'
  private grids = new Map<number, GridCache>() // small LRU keyed by integer zoom bucket
  private cellCounts?: { key: Grid; frame: Uint8Array; counts: Uint32Array }
  private raf = 0
  private paneName: string
  onStatus?: (s: LayerStatus) => void
  lastDrawMs = 0

  constructor(pane: string) { super({}); this.paneName = pane }

  setData(pos: Positions) { this.pos = pos; this.grids.clear(); this.cellCounts = undefined; this.schedule() }
  setFrame(frame: Uint8Array) { this.frame = frame; this.schedule() }
  setMode(m: ViewMode) { this.mode = m; this.schedule() }
  /** Synchronous redraw, for tests and measurements. */
  drawNow() { this.cancel(); this.draw() }

  onAdd(map: L.Map) {
    this.canvas = L.DomUtil.create('canvas', 'leaflet-zoom-hide') as HTMLCanvasElement
    this.canvas.style.pointerEvents = 'none'
    this.canvas.dataset.testid = 'agent-canvas'
    map.getPane(this.paneName)!.appendChild(this.canvas)
    map.on('move zoomend resize', this.schedule, this)
    map.on('zoomstart', this.hide, this)
    this.schedule()
    return this
  }
  onRemove(map: L.Map) {
    this.cancel()
    map.off('move zoomend resize', this.schedule, this)
    map.off('zoomstart', this.hide, this)
    this.canvas?.remove()
    return this
  }
  private hide = () => { if (this.canvas) this.canvas.style.opacity = '0' }
  private cancel() { if (this.raf) { cancelAnimationFrame(this.raf); this.raf = 0 } }
  private schedule = () => { if (!this.raf) this.raf = requestAnimationFrame(() => { this.raf = 0; this.draw() }) }

  private gridFor(zb: number): GridCache {
    let g = this.grids.get(zb)
    if (g) { this.grids.delete(zb); this.grids.set(zb, g); return g }
    const grid = buildGrid(this.pos!, zb)
    const totals = new Uint32Array(grid.ncells)
    for (let i = 0; i < grid.cell.length; i++) totals[grid.cell[i]]++
    const occ: number[] = []
    let maxTotal = 0
    for (let c = 0; c < totals.length; c++) if (totals[c]) { occ.push(c); if (totals[c] > maxTotal) maxTotal = totals[c] }
    g = { grid, occupied: Int32Array.from(occ), totals, maxTotal }
    this.grids.set(zb, g)
    while (this.grids.size > 3) this.grids.delete(this.grids.keys().next().value as number)
    return g
  }

  /** Container-space projection helpers for the current view. */
  private view() {
    const map = this._map, z = map.getZoom(), scale = 256 * 2 ** z, o = map.project(map.containerPointToLatLng([0, 0]), z)
    return { map, z, scale, ox: o.x, oy: o.y, size: map.getSize() }
  }

  private draw() {
    const map = this._map, c = this.canvas
    if (!map || !c) return
    const t0 = performance.now()
    const v = this.view(), dpr = Math.min(window.devicePixelRatio || 1, 2)
    if (c.width !== Math.round(v.size.x * dpr) || c.height !== Math.round(v.size.y * dpr)) {
      c.width = Math.round(v.size.x * dpr); c.height = Math.round(v.size.y * dpr)
      c.style.width = `${v.size.x}px`; c.style.height = `${v.size.y}px`
    }
    c.style.opacity = '1'
    L.DomUtil.setPosition(c, map.containerPointToLayerPoint([0, 0]))
    const ctx = c.getContext('2d')!
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    ctx.clearRect(0, 0, v.size.x, v.size.y)
    if (!this.pos || !this.frame) return

    let status: LayerStatus
    if (v.z >= INDIVIDUAL_ZOOM) status = this.drawIndividuals(ctx, v)
    else status = this.drawGrid(ctx, v)
    this.lastDrawMs = performance.now() - t0
    status.drawMs = this.lastDrawMs
    this.onStatus?.(status)
  }

  private drawGrid(ctx: CanvasRenderingContext2D, v: ReturnType<AgentLayer['view']>): LayerStatus {
    const gc = this.gridFor(Math.max(0, Math.floor(v.z))), g = gc.grid
    if (!this.cellCounts || this.cellCounts.key !== g || this.cellCounts.frame !== this.frame) this.cellCounts = { key: g, frame: this.frame!, counts: gridCounts(g, this.frame!) }
    const counts = this.cellCounts.counts
    // x edges are linear in longitude; y edges are Mercator per row
    const x0 = (lon: number) => ((lon + 180) / 360) * v.scale - v.ox
    const yEdge = (lat: number) => merc(lat) * v.scale - v.oy
    const logMax = Math.log1p(gc.maxTotal)
    let drawn = 0, agents = 0
    for (let k = 0; k < gc.occupied.length; k++) {
      const cell = gc.occupied[k], cx = g.cx0 + (cell % g.w), cy = g.cy0 + Math.floor(cell / g.w)
      const xa = x0(cx * g.cellLon), xb = x0((cx + 1) * g.cellLon)
      if (xb < -2 || xa > v.size.x + 2) continue
      const yb = yEdge(cy * g.cellLat), ya = yEdge((cy + 1) * g.cellLat) // north edge has the smaller y
      if (yb < -2 || ya > v.size.y + 2) continue
      const o = cell * 4, total = gc.totals[cell]
      const [r, gg, b] = this.mode === 'composition' ? mixColor(counts, o) : prevalenceColor((counts[o + 1] + counts[o + 2]) / total)
      ctx.fillStyle = `rgba(${r},${gg},${b},${(0.3 + 0.66 * (Math.log1p(total) / logMax)).toFixed(3)})`
      ctx.fillRect(xa, ya, Math.max(1, xb - xa - 0.6), Math.max(1, yb - ya - 0.6))
      drawn++; agents += total
    }
    return { mode: 'grid', zoom: v.z, cells: drawn, visibleAgents: agents, drawMs: 0 }
  }

  private drawIndividuals(ctx: CanvasRenderingContext2D, v: ReturnType<AgentLayer['view']>): LayerStatus {
    const p = this.pos!, f = this.frame!, r = dotRadius(v.z), W = v.size.x + r, H = v.size.y + r
    const px = new Float32Array(p.n), py = new Float32Array(p.n)
    const inView = new Uint8Array(p.n)
    let visible = 0
    for (let i = 0; i < p.n; i++) {
      const x = p.mx[i] * v.scale - v.ox, y = p.my[i] * v.scale - v.oy
      if (x < -r || y < -r || x > W || y > H) continue
      px[i] = x; py[i] = y; inView[i] = 1; visible++
    }
    ctx.globalAlpha = 0.88
    // draw order S, R, E, I: the clinically relevant states are never hidden under susceptible dots at shared home locations
    for (const s of [0, 3, 1, 2]) {
      const [cr, cg, cb] = STATE_RGB[s]
      ctx.fillStyle = `rgb(${cr},${cg},${cb})`
      ctx.beginPath()
      for (let i = 0; i < p.n; i++) {
        if (!inView[i] || f[i] !== s) continue
        ctx.moveTo(px[i] + r, py[i]); ctx.arc(px[i], py[i], r, 0, TAU)
      }
      ctx.fill()
    }
    ctx.globalAlpha = 1
    return { mode: 'individual', zoom: v.z, cells: 0, visibleAgents: visible, drawMs: 0 }
  }

  /** What is under a container point (cell counts or nearest agent), for tooltips. */
  hover(pt: L.Point): HoverInfo | null {
    if (!this._map || !this.pos || !this.frame) return null
    const v = this.view(), p = this.pos
    if (v.z >= INDIVIDUAL_ZOOM) {
      let best = -1, bd = 49 // 7 px
      for (let i = 0; i < p.n; i++) {
        const dx = p.mx[i] * v.scale - v.ox - pt.x, dy = p.my[i] * v.scale - v.oy - pt.y, d = dx * dx + dy * dy
        if (d <= bd) { bd = d; best = i }
      }
      return best < 0 ? null : { kind: 'agent', id: best, state: this.frame[best], lon: p.lon[best], lat: p.lat[best] }
    }
    const gc = this.gridFor(Math.max(0, Math.floor(v.z))), g = gc.grid
    const lon = ((pt.x + v.ox) / v.scale) * 360 - 180, lat = invMercLat((pt.y + v.oy) / v.scale)
    const cx = Math.floor(lon / g.cellLon) - g.cx0, cy = Math.floor(lat / g.cellLat) - g.cy0
    if (cx < 0 || cy < 0 || cx >= g.w || cy >= g.h) return null
    const cell = cy * g.w + cx
    if (!gc.totals[cell] || !this.cellCounts || this.cellCounts.key !== g) return null
    const o = cell * 4, c = this.cellCounts.counts
    return { kind: 'cell', counts: [c[o], c[o + 1], c[o + 2], c[o + 3]], lon, lat }
  }
}
