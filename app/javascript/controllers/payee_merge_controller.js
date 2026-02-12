import { Controller } from "@hotwired/stimulus"

// Manages payee selection for merging
export default class extends Controller {
  static targets = ["checkbox", "selectedCount", "mergeForm", "mergeTarget", "mergeBtn"]

  connect() {
    this.updateUI()
  }

  toggle() {
    this.updateUI()
  }

  updateUI() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const count = checked.length

    this.selectedCountTarget.textContent = count
    this.mergeBtnTarget.disabled = count < 2

    if (count >= 2) {
      this.mergeFormTarget.classList.remove("hidden")
    } else {
      this.mergeFormTarget.classList.add("hidden")
    }
  }

  getSelectedPayees() {
    return this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }
}
