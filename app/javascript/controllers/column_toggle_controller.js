import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    columns: Array,
    visible: Array,
    url: String
  }

  toggle(event) {
    const key = event.target.value
    const checked = event.target.checked
    let visible = [...this.visibleValue]

    if (checked && !visible.includes(key)) {
      visible.push(key)
    } else if (!checked) {
      visible = visible.filter(k => k !== key)
    }

    this.visibleValue = visible
    this.#updateColumnVisibility()
    this.#persist()
  }

  #updateColumnVisibility() {
    const allKeys = this.columnsValue.map(c => c.key)
    allKeys.forEach(key => {
      const elements = document.querySelectorAll(`[data-column="${key}"]`)
      elements.forEach(el => {
        if (this.visibleValue.includes(key)) {
          el.classList.remove("hidden")
        } else {
          el.classList.add("hidden")
        }
      })
    })
  }

  #persist() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: JSON.stringify({
        page_key: "transactions",
        visible_columns: this.visibleValue
      })
    })
  }
}
