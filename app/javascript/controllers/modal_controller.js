import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "backdrop"]

  open() {
    this.dialogTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    this.dialogTarget.setAttribute("aria-hidden", "false")

    requestAnimationFrame(() => {
      this.backdropTarget?.classList.add("opacity-100")
      this.backdropTarget?.classList.remove("opacity-0")
    })
  }

  close() {
    this.backdropTarget?.classList.add("opacity-0")
    this.backdropTarget?.classList.remove("opacity-100")
    document.body.style.overflow = ""
    this.dialogTarget.setAttribute("aria-hidden", "true")

    setTimeout(() => {
      this.dialogTarget.classList.add("hidden")
    }, 200)
  }

  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
