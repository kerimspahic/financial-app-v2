import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "firstInput"]
  static values = {
    transactionId: Number,
    tableConfig: String,
    visibleColumns: String
  }

  // Called from the row via dblclick action: dblclick->inline-edit#edit
  edit(event) {
    // Don't trigger inline edit if clicking a link, button, or checkbox
    const tag = event.target.tagName.toLowerCase()
    if (tag === "a" || tag === "button" || tag === "input" || event.target.closest("a") || event.target.closest("button")) {
      return
    }

    const row = event.currentTarget
    if (!row) return

    const transactionId = row.dataset.transactionId
    if (!transactionId) return

    // Fetch the inline edit form via turbo
    this.fetchInlineEditRow(transactionId, row)
  }

  // Edit a specific transaction by ID (called from keyboard shortcuts)
  editTransaction(transactionId) {
    const row = document.getElementById(`transaction_${transactionId}`)
    if (row) {
      this.fetchInlineEditRow(transactionId, row)
    }
  }

  async fetchInlineEditRow(transactionId, row) {
    try {
      const response = await fetch(`/transactions/${transactionId}/edit?inline=true`, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        // Fallback: open the normal edit modal
        const editLink = row.querySelector(`a[href*="/transactions/${transactionId}/edit"]`)
        if (editLink) editLink.click()
        return
      }

      // For now, use the simpler approach: directly replace the row with inline edit form
      // by dispatching a custom event that the inline_edit_row template handles
      this.replaceRowWithInlineForm(row, transactionId)
    } catch {
      // Silently fail, user can still use the modal edit
    }
  }

  replaceRowWithInlineForm(row, transactionId) {
    // Build the inline edit URL and form
    const formUrl = `/transactions/${transactionId}/inline_update`
    const cells = row.querySelectorAll("td")

    // Store original HTML so we can restore on cancel
    row.dataset.originalHtml = row.innerHTML

    // Create inline form
    const formHtml = this.buildInlineForm(row, transactionId, formUrl)
    row.innerHTML = formHtml
    row.classList.add("bg-primary-50/10", "dark:bg-primary-500/5")
    row.classList.remove("hover:bg-surface-hover/50")

    // Focus first editable input
    const firstInput = row.querySelector("input[type=text], input[type=number]")
    if (firstInput) {
      firstInput.focus()
      firstInput.select()
    }

    // Add event listeners for save/cancel
    this.setupInlineFormHandlers(row, transactionId)
  }

  buildInlineForm(row, transactionId, formUrl) {
    // Extract current values from the row data attributes
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    return `
      <td class="px-3 py-2.5" colspan="100%">
        <form action="${formUrl}" method="post" data-inline-row-form="true" data-transaction-id="${transactionId}" class="flex items-center gap-3">
          <input type="hidden" name="_method" value="patch">
          <input type="hidden" name="authenticity_token" value="${csrfToken}">
          <div class="flex items-center gap-2 flex-1">
            <span class="text-xs text-primary-600 dark:text-primary-400 font-medium whitespace-nowrap">Editing:</span>
            <p class="text-xs text-text-muted">Use the full edit form for all fields. Double-click to inline edit is a quick shortcut.</p>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <button type="button" data-inline-cancel="true"
              class="p-1.5 rounded-lg hover:bg-surface-hover text-text-muted hover:text-danger-600 transition-all text-xs">
              Cancel (Esc)
            </button>
            <a href="/transactions/${transactionId}/edit" data-turbo-frame="modal"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg gradient-primary text-white shadow-sm hover:shadow-md transition-all">
              Open Editor
            </a>
          </div>
        </form>
      </td>
    `
  }

  setupInlineFormHandlers(row, transactionId) {
    // Cancel button
    const cancelBtn = row.querySelector("[data-inline-cancel]")
    if (cancelBtn) {
      cancelBtn.addEventListener("click", () => this.cancelEdit(row))
    }

    // Escape key
    row.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.cancelEdit(row)
      }
    })
  }

  cancelEdit(row) {
    const originalHtml = row.dataset.originalHtml
    if (originalHtml) {
      row.innerHTML = originalHtml
      row.classList.remove("bg-primary-50/10", "dark:bg-primary-500/5")
      row.classList.add("hover:bg-surface-hover/50")
      delete row.dataset.originalHtml
    }
  }

  cancel(event) {
    const row = event.target.closest("tr")
    if (row) {
      this.cancelEdit(row)
    }
  }

  save(event) {
    event.preventDefault()
    const form = event.target.closest("form") || this.formTarget
    if (form) {
      form.requestSubmit()
    }
  }
}
