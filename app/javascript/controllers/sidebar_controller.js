import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "content", "label", "logo", "logoIcon", "nav"]

  connect() {
    this.applyState()
    this.restoreScrollPosition()
    this.handleResize = this.handleResize.bind(this)
    this.saveBeforeVisit = this.saveScrollPosition.bind(this)
    window.addEventListener("resize", this.handleResize)
    document.addEventListener("turbo:before-visit", this.saveBeforeVisit)
    // Enable transitions after initial state is applied (prevents flash on load)
    requestAnimationFrame(() => document.documentElement.classList.add("sidebar-ready"))
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
    document.removeEventListener("turbo:before-visit", this.saveBeforeVisit)
  }

  saveScrollPosition() {
    if (this.hasNavTarget) {
      sessionStorage.setItem("sidebarScrollTop", this.navTarget.scrollTop)
    }
  }

  restoreScrollPosition() {
    if (this.hasNavTarget) {
      const saved = sessionStorage.getItem("sidebarScrollTop")
      if (saved) this.navTarget.scrollTop = parseInt(saved, 10)
    }
  }

  toggle() {
    const expanded = !this.isExpanded
    localStorage.setItem("sidebarExpanded", expanded)
    this.applyState()
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.overlayTarget.classList.add("opacity-100")
    })
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.remove("opacity-100")
    setTimeout(() => this.overlayTarget.classList.add("hidden"), 300)
  }

  // Widths and label/logo visibility are driven by the `sidebar-collapsed` class on <html>.
  // CSS handles layout (see application.css); JS toggles the class and also manages
  // the `hidden` class on label/logo targets for Stimulus target consistency.
  applyState() {
    const expanded = this.isExpanded

    if (this.isMobile) {
      this.sidebarTarget.classList.add("-translate-x-full")
      document.documentElement.classList.remove("sidebar-collapsed")
    } else {
      this.sidebarTarget.classList.remove("-translate-x-full")
      document.documentElement.classList.toggle("sidebar-collapsed", !expanded)
    }

    this.labelTargets.forEach(el => el.classList.toggle("hidden", !expanded && !this.isMobile))

    if (this.hasLogoTarget) {
      this.logoTarget.classList.toggle("hidden", !expanded && !this.isMobile)
    }
    if (this.hasLogoIconTarget) {
      this.logoIconTarget.classList.toggle("hidden", expanded || this.isMobile)
    }
  }

  handleResize() {
    this.applyState()
    if (!this.isMobile) {
      this.overlayTarget.classList.add("hidden")
      this.overlayTarget.classList.remove("opacity-100")
    }
  }

  get isExpanded() {
    const stored = localStorage.getItem("sidebarExpanded")
    if (stored !== null) return stored === "true"
    return !this.isMobile
  }

  get isMobile() {
    return window.innerWidth < 1024
  }
}
