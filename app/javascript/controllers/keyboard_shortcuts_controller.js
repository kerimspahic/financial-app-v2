import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "tableBody", "helpModal"]
  static values = {
    newUrl: String
  }

  connect() {
    this.selectedIndex = -1
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    // Don't handle shortcuts when typing in inputs, textareas, or selects
    const target = event.target
    const tagName = target.tagName.toLowerCase()
    if (tagName === "input" || tagName === "textarea" || tagName === "select" || target.isContentEditable) {
      // Allow Escape to blur the field
      if (event.key === "Escape") {
        target.blur()
        event.preventDefault()
      }
      return
    }

    // Don't handle if a modal is open
    const modal = document.querySelector("[data-modal-target='dialog']:not(.hidden)")
    if (modal) return

    switch (event.key) {
      case "n":
        event.preventDefault()
        this.openNewTransaction()
        break
      case "j":
        event.preventDefault()
        this.navigateDown()
        break
      case "k":
        event.preventDefault()
        this.navigateUp()
        break
      case "e":
        event.preventDefault()
        this.editSelected()
        break
      case "Enter":
        event.preventDefault()
        this.viewSelected()
        break
      case "f":
      case "/":
        event.preventDefault()
        this.focusSearch()
        break
      case "?":
        event.preventDefault()
        this.showHelp()
        break
      case "Escape":
        this.hideHelp()
        break
    }
  }

  openNewTransaction() {
    // Click the "New Transaction" button which opens the modal
    const newBtn = document.querySelector(`a[href="${this.newUrlValue}"]`)
    if (newBtn) {
      newBtn.click()
    }
  }

  navigateDown() {
    const rows = this.getRows()
    if (rows.length === 0) return

    this.clearSelection()
    this.selectedIndex = Math.min(this.selectedIndex + 1, rows.length - 1)
    this.highlightRow(rows[this.selectedIndex])
  }

  navigateUp() {
    const rows = this.getRows()
    if (rows.length === 0) return

    this.clearSelection()
    this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
    this.highlightRow(rows[this.selectedIndex])
  }

  editSelected() {
    const rows = this.getRows()
    if (this.selectedIndex < 0 || this.selectedIndex >= rows.length) return

    const row = rows[this.selectedIndex]
    const editLink = row.querySelector("a[href*='/edit']")
    if (editLink) {
      editLink.click()
    }
  }

  viewSelected() {
    const rows = this.getRows()
    if (this.selectedIndex < 0 || this.selectedIndex >= rows.length) return

    const row = rows[this.selectedIndex]
    // Find the view link (the eye icon link) or the description link
    const viewLink = row.querySelector("a[data-turbo-frame='modal']")
    if (viewLink) {
      viewLink.click()
    }
  }

  focusSearch() {
    const searchInput = document.querySelector("[data-table-search-target='input']")
    if (searchInput) {
      searchInput.focus()
      searchInput.select()
    }
  }

  showHelp() {
    if (this.hasHelpModalTarget) {
      this.helpModalTarget.classList.remove("hidden")
      document.body.style.overflow = "hidden"
    }
  }

  hideHelp() {
    if (this.hasHelpModalTarget) {
      this.helpModalTarget.classList.add("hidden")
      document.body.style.overflow = ""
    }
  }

  getRows() {
    if (this.hasTableBodyTarget) {
      return Array.from(this.tableBodyTarget.querySelectorAll("tr[data-transaction-id]"))
    }
    return this.hasRowTarget ? this.rowTargets : []
  }

  clearSelection() {
    const rows = this.getRows()
    rows.forEach(row => {
      row.classList.remove("selected", "ring-2", "ring-primary-500/30", "bg-primary-50/5", "dark:bg-primary-500/5")
    })
  }

  highlightRow(row) {
    if (!row) return
    row.classList.add("selected", "ring-2", "ring-primary-500/30", "bg-primary-50/5", "dark:bg-primary-500/5")
    row.scrollIntoView({ block: "nearest", behavior: "smooth" })
  }
}
