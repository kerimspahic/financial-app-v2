import { Controller } from "@hotwired/stimulus"

// Manages the currency conversion UI on the transaction form.
// Shows/hides the currency section based on whether a foreign currency is selected.
// Fetches live exchange rates and computes the converted amount.
export default class extends Controller {
  static targets = ["currencySection", "currencySelect", "originalAmount", "exchangeRate", "convertedPreview"]

  connect() {
    this.toggleCurrencySection()
  }

  toggleCurrencySection() {
    const currency = this.currencySelectTarget.value
    const isVisible = currency && currency !== "USD"

    if (this.hasCurrencySectionTarget) {
      this.currencySectionTarget.classList.toggle("hidden", !isVisible)
    }

    if (!isVisible) {
      // Reset fields when switching back to USD
      if (this.hasOriginalAmountTarget) this.originalAmountTarget.value = ""
      if (this.hasExchangeRateTarget) this.exchangeRateTarget.value = ""
      if (this.hasConvertedPreviewTarget) this.convertedPreviewTarget.textContent = ""
    }
  }

  async fetchRate() {
    const currency = this.currencySelectTarget.value
    const originalAmount = parseFloat(this.originalAmountTarget.value)

    if (!currency || currency === "USD" || !originalAmount || originalAmount <= 0) {
      return
    }

    try {
      const response = await fetch(`/exchanges/rate?from=${currency}&to=USD&amount=${originalAmount}`)
      if (response.ok) {
        const data = await response.json()
        this.exchangeRateTarget.value = data.rate
        if (this.hasConvertedPreviewTarget) {
          this.convertedPreviewTarget.textContent = `= $${data.converted_amount.toFixed(2)} USD`
        }
      }
    } catch (error) {
      console.error("Failed to fetch exchange rate:", error)
    }
  }
}
