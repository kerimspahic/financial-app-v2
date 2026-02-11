import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String, position: { type: String, default: "top" } }

  connect() {
    this.tooltip = null
    this.showTimeout = null
    this.boundShow = this.show.bind(this)
    this.boundHide = this.hide.bind(this)
    this.element.addEventListener("mouseenter", this.boundShow)
    this.element.addEventListener("mouseleave", this.boundHide)
  }

  disconnect() {
    this.element.removeEventListener("mouseenter", this.boundShow)
    this.element.removeEventListener("mouseleave", this.boundHide)
    this.hide()
  }

  get isTruncated() {
    // Check the element itself
    if (this.element.scrollWidth > this.element.clientWidth) return true

    // Check any child with .truncate class
    const truncated = this.element.querySelectorAll(".truncate")
    for (const el of truncated) {
      if (el.scrollWidth > el.clientWidth) return true
    }

    // Check overflow-hidden containers with content wider than container
    if (this.element.classList.contains("overflow-hidden")) {
      if (this.element.scrollWidth > this.element.clientWidth) return true
    }

    return false
  }

  show() {
    if (!this.textValue || !this.isTruncated) return

    this.showTimeout = setTimeout(() => {
      this.tooltip = document.createElement("div")
      this.tooltip.className = "tooltip-popup"
      this.tooltip.textContent = this.textValue
      document.body.appendChild(this.tooltip)

      this.positionTooltip()

      requestAnimationFrame(() => {
        if (this.tooltip) this.tooltip.classList.add("tooltip-visible")
      })
    }, 400)
  }

  hide() {
    clearTimeout(this.showTimeout)
    if (this.tooltip) {
      this.tooltip.classList.remove("tooltip-visible")
      const el = this.tooltip
      setTimeout(() => el.remove(), 150)
      this.tooltip = null
    }
  }

  positionTooltip() {
    if (!this.tooltip) return

    const rect = this.element.getBoundingClientRect()
    const tipRect = this.tooltip.getBoundingClientRect()
    const gap = 8
    const padding = 12

    let top, left

    if (this.positionValue === "bottom") {
      top = rect.bottom + gap
      left = rect.left + rect.width / 2 - tipRect.width / 2
    } else {
      top = rect.top - tipRect.height - gap
      left = rect.left + rect.width / 2 - tipRect.width / 2
    }

    // Keep within viewport
    if (left < padding) left = padding
    if (left + tipRect.width > window.innerWidth - padding) {
      left = window.innerWidth - tipRect.width - padding
    }
    if (top < padding) {
      top = rect.bottom + gap
    }

    this.tooltip.style.top = `${top}px`
    this.tooltip.style.left = `${left}px`
  }
}
