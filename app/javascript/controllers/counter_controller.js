import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "value" ]
  static values = {
    end: Number,
    duration: { type: Number, default: 1000 },
    prefix: { type: String, default: "" },
    suffix: { type: String, default: "" }
  }

  connect() {
    if (!this.hasValueTarget) return

    // Parse the displayed text to extract number and formatting
    const text = this.valueTarget.textContent.trim()
    this.originalText = text
    this.parseFormat(text)
    this.animate()
  }

  parseFormat(text) {
    // Extract prefix (like $), suffix, and number
    const match = text.match(/^([^0-9-]*)([-]?[\d,]+\.?\d*)(.*)$/)
    if (match) {
      this.displayPrefix = match[1]
      this.targetNumber = parseFloat(match[2].replace(/,/g, ""))
      this.displaySuffix = match[3]
      this.decimals = match[2].includes(".") ? match[2].split(".")[1].length : 0
    } else {
      this.targetNumber = 0
      this.displayPrefix = ""
      this.displaySuffix = ""
      this.decimals = 0
    }
  }

  animate() {
    const duration = this.durationValue
    const startTime = performance.now()
    const endValue = this.targetNumber

    const step = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)

      // Ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3)
      const current = endValue * eased

      this.valueTarget.textContent = this.formatNumber(current)

      if (progress < 1) {
        requestAnimationFrame(step)
      } else {
        // Restore exact original text to avoid formatting drift
        this.valueTarget.textContent = this.originalText
      }
    }

    requestAnimationFrame(step)
  }

  formatNumber(value) {
    const formatted = Math.abs(value).toFixed(this.decimals)
      .replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    const sign = value < 0 ? "-" : ""
    return `${this.displayPrefix}${sign}${formatted}${this.displaySuffix}`
  }
}
