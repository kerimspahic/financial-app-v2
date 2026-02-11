import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  async connect() {
    const { default: Sortable } = await import("sortablejs")

    this.sortable = Sortable.create(this.element, {
      animation: 200,
      ghostClass: "opacity-30",
      chosenClass: "scale-[1.02]",
      dragClass: "shadow-2xl",
      handle: "[data-sortable-handle]",
      draggable: "[data-sortable-id]",
      onEnd: this.handleEnd.bind(this)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  handleEnd() {
    const items = this.element.querySelectorAll("[data-sortable-id]")
    const positions = {}

    items.forEach((item, index) => {
      positions[item.dataset.sortableId] = index
    })

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({ positions })
    })
  }
}
