import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = { sidebarAware: { type: Boolean, default: false } }

  toggle() {
    // When sidebar is collapsed, expand it instead of opening the dropdown
    if (this.sidebarAwareValue) {
      const ctrl = this.findSidebarController()
      if (ctrl && !ctrl.isExpanded && !ctrl.isMobile) {
        ctrl.toggle()
        return
      }
    }

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

  handleClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  handleEscape = (event) => {
    if (event.key === "Escape") {
      this.hide()
    }
  }

  collapseSidebar() {
    this.hide()
    this.findSidebarController()?.toggle()
  }

  // Looks up the sidebar controller via DOM query since there's no built-in
  // Stimulus mechanism for cross-controller communication.
  findSidebarController() {
    const el = document.querySelector('[data-controller~="sidebar"]')
    if (!el) return null
    return this.application.getControllerForElementAndIdentifier(el, "sidebar")
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleEscape)
  }
}
