import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statementBalance", "clearedBalance", "difference", "checkbox", "selectAll", "selectedCount", "selectedTotal"]

  calculate() {
    const statementBalance = parseFloat(this.statementBalanceTarget.value) || 0
    let selectedTotal = 0
    let selectedCount = 0

    this.checkboxTargets.forEach(cb => {
      if (cb.checked) {
        selectedTotal += parseFloat(cb.dataset.amount) || 0
        selectedCount++
      }
    })

    const difference = statementBalance - selectedTotal

    this.selectedCountTarget.textContent = selectedCount
    this.selectedTotalTarget.textContent = this.formatCurrency(selectedTotal)

    this.differenceTarget.textContent = this.formatCurrency(difference)
    this.differenceTarget.className = `text-2xl font-bold ${Math.abs(difference) < 0.01 ? 'text-success-600' : 'text-danger-600'}`
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => { cb.checked = checked })
    this.calculate()
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount)
  }
}
