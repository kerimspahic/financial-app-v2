import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "total", "toggleBtn", "splitSection"]

  connect() {
    this.updateTotal()
  }

  toggle() {
    const section = this.splitSectionTarget
    section.classList.toggle("hidden")
    if (!section.classList.contains("hidden") && this.containerTarget.children.length === 0) {
      this.addRow()
    }
  }

  addRow() {
    const template = this.templateTarget.content.cloneNode(true)
    const timestamp = new Date().getTime()
    // Replace NEW_RECORD placeholder with unique timestamp
    template.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace(/NEW_RECORD/g, timestamp)
    })
    this.containerTarget.appendChild(template)
    this.updateTotal()
  }

  removeRow(event) {
    const row = event.target.closest("[data-split-row]")
    const destroyInput = row.querySelector("input[name*='_destroy']")
    if (destroyInput) {
      // Existing record: mark for destruction and hide
      destroyInput.value = "1"
      row.classList.add("hidden")
    } else {
      // New record: remove from DOM
      row.remove()
    }
    this.updateTotal()
  }

  updateTotal() {
    const inputs = this.containerTarget.querySelectorAll("input[name*='[amount]']")
    let total = 0
    inputs.forEach(input => {
      const row = input.closest("[data-split-row]")
      const destroyInput = row?.querySelector("input[name*='_destroy']")
      if (destroyInput && destroyInput.value === "1") return
      total += parseFloat(input.value) || 0
    })
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `$${total.toFixed(2)}`
    }
  }
}
