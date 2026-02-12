import { Controller } from "@hotwired/stimulus"

// Manages the dynamic actions builder for categorization rules
export default class extends Controller {
  static targets = ["container", "hiddenField", "template", "actionType"]
  static values = {
    actions: { type: Array, default: [] },
    categories: { type: Array, default: [] },
    tags: { type: Array, default: [] }
  }

  connect() {
    this.renderActions()
  }

  addAction() {
    const type = this.actionTypeTarget.value
    if (!type) return

    const actions = [...this.actionsValue]
    const newAction = { type, value: "" }

    // Set default values for boolean actions
    if (type === "mark_reviewed" || type === "exclude_from_reports") {
      newAction.value = "true"
    }

    actions.push(newAction)
    this.actionsValue = actions
    this.actionTypeTarget.value = ""
    this.renderActions()
    this.updateHiddenField()
  }

  removeAction(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    const actions = [...this.actionsValue]
    actions.splice(index, 1)
    this.actionsValue = actions
    this.renderActions()
    this.updateHiddenField()
  }

  updateActionValue(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    const actions = [...this.actionsValue]
    actions[index] = { ...actions[index], value: event.currentTarget.value }
    this.actionsValue = actions
    this.updateHiddenField()
  }

  renderActions() {
    const actions = this.actionsValue
    this.containerTarget.innerHTML = ""

    actions.forEach((action, index) => {
      const row = document.createElement("div")
      row.className = "flex items-center gap-3 p-3 rounded-xl glass border border-glass-border animate-fade-up"
      row.innerHTML = this.actionRowHTML(action, index)
      this.containerTarget.appendChild(row)
    })

    this.updateHiddenField()
  }

  actionRowHTML(action, index) {
    const label = this.actionLabel(action.type)
    const valueInput = this.valueInputHTML(action, index)

    return `
      <div class="flex-shrink-0">
        <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium bg-primary-50 dark:bg-primary-500/10 text-primary-700 dark:text-primary-300">
          ${label}
        </span>
      </div>
      <div class="flex-1 min-w-0">
        ${valueInput}
      </div>
      <button type="button"
              data-action="click->rule-actions#removeAction"
              data-index="${index}"
              class="flex-shrink-0 p-1.5 rounded-lg hover:bg-surface-hover text-text-muted hover:text-danger-600 transition-all">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    `
  }

  actionLabel(type) {
    const labels = {
      set_category: "Set Category",
      add_tag: "Add Tag",
      set_payee: "Set Payee",
      set_notes: "Set Notes",
      set_flag: "Set Flag",
      mark_reviewed: "Mark Reviewed",
      exclude_from_reports: "Exclude from Reports"
    }
    return labels[type] || type
  }

  valueInputHTML(action, index) {
    const inputClass = "block w-full rounded-lg border border-input-border px-3 py-1.5 text-sm glass text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-input-focus focus:border-transparent transition-all"

    switch (action.type) {
      case "set_category":
        return this.selectHTML(this.categoriesValue, action.value, index, inputClass, "Select category...")
      case "add_tag":
        return this.selectHTML(this.tagsValue, action.value, index, inputClass, "Select tag...")
      case "set_flag":
        return this.selectHTML(
          [
            { id: "red", name: "Red" },
            { id: "orange", name: "Orange" },
            { id: "yellow", name: "Yellow" },
            { id: "green", name: "Green" },
            { id: "blue", name: "Blue" },
            { id: "purple", name: "Purple" }
          ],
          action.value,
          index,
          inputClass,
          "Select flag..."
        )
      case "set_payee":
        return `<input type="text" value="${this.escapeHTML(action.value || '')}"
                  data-action="input->rule-actions#updateActionValue"
                  data-index="${index}"
                  placeholder="Payee name"
                  class="${inputClass}" />`
      case "set_notes":
        return `<input type="text" value="${this.escapeHTML(action.value || '')}"
                  data-action="input->rule-actions#updateActionValue"
                  data-index="${index}"
                  placeholder="Notes text"
                  class="${inputClass}" />`
      case "mark_reviewed":
      case "exclude_from_reports":
        return `<span class="text-sm text-text-muted italic">Automatic</span>`
      default:
        return `<input type="text" value="${this.escapeHTML(action.value || '')}"
                  data-action="input->rule-actions#updateActionValue"
                  data-index="${index}"
                  placeholder="Value"
                  class="${inputClass}" />`
    }
  }

  selectHTML(options, selectedValue, index, inputClass, placeholder) {
    const optionsHTML = options.map(opt => {
      const id = String(opt.id || opt)
      const name = opt.name || opt
      const selected = String(selectedValue) === id ? "selected" : ""
      return `<option value="${id}" ${selected}>${this.escapeHTML(name)}</option>`
    }).join("")

    return `<select data-action="change->rule-actions#updateActionValue"
                    data-index="${index}"
                    class="${inputClass}">
              <option value="">${placeholder}</option>
              ${optionsHTML}
            </select>`
  }

  updateHiddenField() {
    this.hiddenFieldTarget.value = JSON.stringify(this.actionsValue)
  }

  escapeHTML(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
