import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: { type: Array, default: [] },
    color: { type: String, default: "#10b981" },
    width: { type: Number, default: 140 },
    height: { type: Number, default: 28 }
  }

  connect() {
    if (this.dataValue.length < 2) return
    this.render()
  }

  render() {
    const data = this.dataValue
    const w = this.widthValue
    const h = this.heightValue
    const padding = 2

    const min = Math.min(...data)
    const max = Math.max(...data)
    const range = max - min || 1

    const points = data.map((val, i) => {
      const x = padding + (i / (data.length - 1)) * (w - 2 * padding)
      const y = h - padding - ((val - min) / range) * (h - 2 * padding)
      return `${x},${y}`
    }).join(" ")

    const firstX = padding
    const lastX = padding + (w - 2 * padding)
    const fillPoints = `${firstX},${h} ${points} ${lastX},${h}`
    const gradientId = `spark-${Math.random().toString(36).slice(2, 9)}`

    this.element.innerHTML = `
      <svg width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" class="overflow-visible">
        <defs>
          <linearGradient id="${gradientId}" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="${this.colorValue}" stop-opacity="0.3"/>
            <stop offset="100%" stop-color="${this.colorValue}" stop-opacity="0.02"/>
          </linearGradient>
        </defs>
        <polygon points="${fillPoints}" fill="url(#${gradientId})"/>
        <polyline points="${points}" fill="none" stroke="${this.colorValue}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    `
  }
}
