import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 5 } }

  connect() {
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue * 1000)
    }
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.style.transition = "opacity 300ms ease-out"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
