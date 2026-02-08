import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "backdrop", "frame"]

  connect() {
    if (this.hasFrameTarget) {
      this.frameTarget.addEventListener("turbo:frame-load", this.handleFrameLoad)
    }
  }

  disconnect() {
    if (this.hasFrameTarget) {
      this.frameTarget.removeEventListener("turbo:frame-load", this.handleFrameLoad)
    }
    document.body.style.overflow = ""
  }

  handleFrameLoad = () => {
    if (this.hasFrameTarget && this.frameTarget.innerHTML.trim() !== "") {
      this.open()
    }
  }

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
      if (this.hasFrameTarget) {
        this.frameTarget.innerHTML = ""
      }
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
