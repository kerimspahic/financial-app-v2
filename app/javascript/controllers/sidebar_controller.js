import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "content", "label", "logo", "logoIcon"]

  connect() {
    this.applyState()
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
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

  applyState() {
    const expanded = this.isExpanded
    const sidebar = this.sidebarTarget
    const content = this.contentTarget

    if (this.isMobile) {
      sidebar.classList.add("-translate-x-full")
      sidebar.style.width = "16rem"
      content.style.marginLeft = "0"
    } else {
      sidebar.classList.remove("-translate-x-full")
      sidebar.style.width = expanded ? "16rem" : "5rem"
      content.style.marginLeft = expanded ? "16rem" : "5rem"
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
