import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "saveForm"]

  save(event) {
    const name = this.nameInputTarget.value.trim()
    if (!name) {
      this.nameInputTarget.focus()
      return
    }

    const button = event.currentTarget
    const url = button.dataset.url
    const pageKey = button.dataset.pageKey
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    // Collect current URL params as filter state
    const currentParams = new URLSearchParams(window.location.search)

    const formData = new FormData()
    formData.append("name", name)
    formData.append("page_key", pageKey)

    // Pass along q params and search
    for (const [key, value] of currentParams.entries()) {
      if (value) formData.append(key, value)
    }

    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    }).then(response => {
      if (response.ok) {
        return response.text()
      }
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
        this.nameInputTarget.value = ""
      }
    })
  }
}
