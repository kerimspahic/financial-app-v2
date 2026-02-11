import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "display", "checkbox"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  update() {
    const selected = this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.dataset.tagName)

    if (selected.length === 0) {
      this.displayTarget.textContent = "Select tags..."
      this.displayTarget.classList.add("text-text-muted")
      this.displayTarget.classList.remove("text-text-primary")
    } else {
      this.displayTarget.textContent = selected.join(", ")
      this.displayTarget.classList.remove("text-text-muted")
      this.displayTarget.classList.add("text-text-primary")
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
