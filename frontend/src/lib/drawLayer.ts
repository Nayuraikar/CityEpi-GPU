import L from 'leaflet'

/** Lightweight canvas layer for large point / grid datasets (tens of thousands of marks). */
export interface DrawSpec {
  draw: (ctx: CanvasRenderingContext2D, map: L.Map) => void
  hit?: (pt: L.Point, map: L.Map) => string | null
}

export class DrawLayer extends L.Layer {
  private canvas?: HTMLCanvasElement
  private spec: DrawSpec
  private paneName: string
  constructor(spec: DrawSpec, pane: string) { super({}); this.spec = spec; this.paneName = pane }

  setSpec(spec: DrawSpec) { this.spec = spec; this.redraw() }
  hit(pt: L.Point): string | null { return this._map && this.spec.hit ? this.spec.hit(pt, this._map) : null }

  onAdd(map: L.Map) {
    this.canvas = L.DomUtil.create('canvas', 'leaflet-zoom-hide') as HTMLCanvasElement
    this.canvas.style.pointerEvents = 'none'
    map.getPane(this.paneName)!.appendChild(this.canvas)
    map.on('moveend zoomend resize', this.redraw, this)
    map.on('zoomstart', this.hide, this)
    this.redraw()
    return this
  }
  onRemove(map: L.Map) {
    map.off('moveend zoomend resize', this.redraw, this)
    map.off('zoomstart', this.hide, this)
    this.canvas?.remove()
    return this
  }
  private hide = () => { if (this.canvas) this.canvas.style.opacity = '0' }
  redraw = () => {
    const map = this._map, c = this.canvas
    if (!map || !c) return
    const size = map.getSize(), dpr = window.devicePixelRatio || 1
    c.width = size.x * dpr; c.height = size.y * dpr
    c.style.width = `${size.x}px`; c.style.height = `${size.y}px`
    c.style.opacity = '1'
    L.DomUtil.setPosition(c, map.containerPointToLayerPoint([0, 0]))
    const ctx = c.getContext('2d')!
    ctx.scale(dpr, dpr)
    this.spec.draw(ctx, map)
  }
}
