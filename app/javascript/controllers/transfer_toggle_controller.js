import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "destinationField"]

  toggle() {
    const isTransfer = this.typeSelectTarget.value === "transfer"
    this.destinationFieldTarget.classList.toggle("hidden", !isTransfer)
  }
}
