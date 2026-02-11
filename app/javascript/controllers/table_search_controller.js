import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]
  static values = { debounce: { type: Number, default: 600 } }

  #timeout = null

  search() {
    clearTimeout(this.#timeout)
    this.#timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, this.debounceValue)
  }

  disconnect() {
    clearTimeout(this.#timeout)
  }
}
