import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "toolbar", "count", "form"]

  connect() {
    this.updateState()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => {
      cb.checked = checked
    })
    this.updateState()
  }

  toggleOne() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    const someChecked = this.checkboxTargets.some(cb => cb.checked)
    this.selectAllTarget.checked = allChecked
    this.selectAllTarget.indeterminate = someChecked && !allChecked
    this.updateState()
  }

  updateState() {
    const selected = this.checkboxTargets.filter(cb => cb.checked)
    const count = selected.length

    if (this.hasToolbarTarget) {
      if (count > 0) {
        this.toolbarTarget.classList.remove("hidden")
      } else {
        this.toolbarTarget.classList.add("hidden")
      }
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = `${count} selected`
    }
  }

  submitBulkUpdate(event) {
    event.preventDefault()
    this._submitBulkForm(event.currentTarget.closest("form") || this.formTarget, "bulk_update")
  }

  submitBulkDestroy(event) {
    event.preventDefault()
    if (!confirm("Are you sure you want to delete the selected transactions?")) return
    this._submitBulkForm(event.currentTarget.closest("form") || this.formTarget, "bulk_destroy")
  }

  _submitBulkForm(form, action) {
    // Clear old hidden transaction_ids
    form.querySelectorAll("input[name='transaction_ids[]'][data-bulk-injected]").forEach(el => el.remove())

    // Add selected transaction IDs
    this.checkboxTargets.filter(cb => cb.checked).forEach(cb => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "transaction_ids[]"
      input.value = cb.value
      input.dataset.bulkInjected = "true"
      form.appendChild(input)
    })

    // Set form action
    if (action === "bulk_update") {
      form.method = "post"
      let methodInput = form.querySelector("input[name='_method']")
      if (!methodInput) {
        methodInput = document.createElement("input")
        methodInput.type = "hidden"
        methodInput.name = "_method"
        form.appendChild(methodInput)
      }
      methodInput.value = "patch"
      form.action = form.dataset.bulkUpdateUrl
    } else {
      form.method = "post"
      let methodInput = form.querySelector("input[name='_method']")
      if (!methodInput) {
        methodInput = document.createElement("input")
        methodInput.type = "hidden"
        methodInput.name = "_method"
        form.appendChild(methodInput)
      }
      methodInput.value = "delete"
      form.action = form.dataset.bulkDestroyUrl
    }

    form.submit()
  }
}
