import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "creditFields", "loanFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.typeSelectTarget.value
    const isCreditCard = type === "credit_card"

    if (this.hasCreditFieldsTarget) {
      this.creditFieldsTarget.classList.toggle("hidden", !isCreditCard)
    }

    if (this.hasLoanFieldsTarget) {
      // Show loan fields for any account type (user opts in by filling them)
      // but hide for credit cards since they use credit_limit instead
      this.loanFieldsTarget.classList.toggle("hidden", isCreditCard)
    }
  }
}
