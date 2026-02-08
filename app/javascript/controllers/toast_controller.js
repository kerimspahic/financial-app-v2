import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flash"]

  connect() {
    this.boundShow = this.show.bind(this)
    document.addEventListener("toast:show", this.boundShow)

    // Show any flash messages rendered in the DOM
    this.flashTargets.forEach(el => {
      this.show({
        detail: {
          message: el.dataset.message,
          variant: el.dataset.variant || "success",
          timeout: parseInt(el.dataset.timeout || "5", 10)
        }
      })
      el.remove()
    })
  }

  disconnect() {
    document.removeEventListener("toast:show", this.boundShow)
  }

  trigger(event) {
    const { toastMessage: message, toastVariant: variant } = event.currentTarget.dataset
    if (message) this.show({ detail: { message, variant: variant || "success" } })
  }

  show(event) {
    const { message, variant = "success", timeout = 5 } = event.detail
    const container = document.getElementById("toast-container")
    if (!container) return

    const toast = document.createElement("div")
    toast.className = "pointer-events-auto animate-slide-in-right"
    toast.innerHTML = this.toastHTML(message, variant)

    container.appendChild(toast)

    // Auto-dismiss
    if (timeout > 0) {
      setTimeout(() => this.dismiss(toast), timeout * 1000)
    }

    // Click to dismiss
    const closeBtn = toast.querySelector("[data-toast-close]")
    if (closeBtn) {
      closeBtn.addEventListener("click", () => this.dismiss(toast))
    }
  }

  dismiss(toast) {
    if (!toast || !toast.parentNode) return
    toast.style.transition = "opacity 300ms ease-out, transform 300ms ease-out"
    toast.style.opacity = "0"
    toast.style.transform = "translateX(100%)"
    setTimeout(() => toast.remove(), 300)
  }

  toastHTML(message, variant) {
    const icons = {
      success: `<svg class="w-5 h-5 text-success-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>`,
      error: `<svg class="w-5 h-5 text-danger-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" /></svg>`,
      warning: `<svg class="w-5 h-5 text-warning-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" /></svg>`,
      info: `<svg class="w-5 h-5 text-info-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" /></svg>`
    }

    const borders = {
      success: "border-l-success-500",
      error: "border-l-danger-500",
      warning: "border-l-warning-500",
      info: "border-l-info-500"
    }

    const icon = icons[variant] || icons.success
    const borderClass = borders[variant] || borders.success

    return `
      <div class="glass-strong rounded-xl shadow-2xl p-4 flex items-start gap-3 min-w-[320px] max-w-md border-l-4 ${borderClass}">
        ${icon}
        <div class="flex-1 text-sm text-text-primary">${this.escapeHtml(message)}</div>
        <button data-toast-close class="shrink-0 text-text-muted hover:text-text-primary transition-colors">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    `
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
