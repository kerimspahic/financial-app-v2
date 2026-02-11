import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) {
      this.panelTarget.classList.remove("hidden")
    }
  }

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }
}
