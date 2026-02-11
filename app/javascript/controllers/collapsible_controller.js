import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: { type: Boolean, default: true } }

  connect() {
    this.update()
  }

  toggle() {
    this.openValue = !this.openValue
    this.update()
  }

  update() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.openValue)
    }
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("-rotate-90", !this.openValue)
    }
  }
}
