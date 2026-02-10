import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "fromCurrency", "toCurrency", "amount",
    "result", "rate", "resultAmount", "error",
    "saveFromCurrency", "saveToCurrency", "saveAmount",
    "providerInfo"
  ]

  static values = {
    url: String
  }

  connect() {
    this.debounceTimer = null
    this.fetchRate()
  }

  convert() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchRate(), 300)
  }

  swap() {
    const from = this.fromCurrencyTarget.value
    const to = this.toCurrencyTarget.value
    this.fromCurrencyTarget.value = to
    this.toCurrencyTarget.value = from
    this.fetchRate()
  }

  async fetchRate() {
    const from = this.fromCurrencyTarget.value
    const to = this.toCurrencyTarget.value
    const amount = parseFloat(this.amountTarget.value) || 1

    if (from === to) {
      this.resultAmountTarget.textContent = this.formatNumber(amount)
      this.rateTarget.textContent = `1 ${from} = 1 ${to}`
      this.syncFormFields(from, to, amount)
      this.hideError()
      return
    }

    try {
      this.resultTarget.classList.add("opacity-50")
      const url = `${this.urlValue}?from=${from}&to=${to}&amount=${amount}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || "Failed to fetch rate")
      }

      const data = await response.json()
      this.resultAmountTarget.textContent = this.formatNumber(data.converted_amount)
      this.rateTarget.textContent = `1 ${from} = ${this.formatNumber(data.rate)} ${to}`
      this.updateProviderInfo(data)
      this.syncFormFields(from, to, amount)
      this.hideError()
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.resultTarget.classList.remove("opacity-50")
    }
  }

  syncFormFields(from, to, amount) {
    if (this.hasSaveFromCurrencyTarget) this.saveFromCurrencyTarget.value = from
    if (this.hasSaveToCurrencyTarget) this.saveToCurrencyTarget.value = to
    if (this.hasSaveAmountTarget) this.saveAmountTarget.value = amount
  }

  formatNumber(num) {
    return parseFloat(parseFloat(num).toFixed(4)).toLocaleString("en-US", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 4
    })
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }

  updateProviderInfo(data) {
    if (!this.hasProviderInfoTarget) return
    if (!data.last_updated || !data.provider) {
      this.providerInfoTarget.classList.add("hidden")
      return
    }

    const updated = new Date(data.last_updated)
    const ago = this.timeAgo(updated)
    this.providerInfoTarget.textContent = `Updated ${ago} ago via ${data.provider}`
    this.providerInfoTarget.classList.remove("hidden")
  }

  timeAgo(date) {
    const seconds = Math.floor((Date.now() - date.getTime()) / 1000)
    if (seconds < 60) return "just now"
    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}m`
    const hours = Math.floor(minutes / 60)
    return `${hours}h`
  }
}
