import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.menuTarget.classList.remove("hidden")
    this.element.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.handleClickOutside)
    document.addEventListener("keydown", this.handleEscape)
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    this.element.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  handleEscape = (event) => {
    if (event.key === "Escape") {
      this.hide()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleEscape)
  }
}
