import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "placeholder", "preview", "filename", "filesize"]

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) {
      this.reset()
      return
    }

    this.filenameTarget.textContent = file.name
    this.filesizeTarget.textContent = this.formatFileSize(file.size)

    this.placeholderTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("flex")
    this.previewTarget.classList.remove("hidden")
    this.previewTarget.classList.add("flex")
  }

  validate(event) {
    const file = this.inputTarget.files[0]
    if (!file) {
      event.preventDefault()
      return
    }

    // Validate file size (5MB max)
    if (file.size > 5 * 1024 * 1024) {
      event.preventDefault()
      alert("File is too large. Maximum size is 5MB.")
      return
    }

    // Validate file type
    const validTypes = ["text/csv", "application/csv", "text/plain", "application/vnd.ms-excel"]
    const validExtension = file.name.toLowerCase().endsWith(".csv")

    if (!validTypes.includes(file.type) && !validExtension) {
      event.preventDefault()
      alert("Please select a CSV file.")
      return
    }
  }

  reset() {
    this.placeholderTarget.classList.remove("hidden")
    this.placeholderTarget.classList.add("flex")
    this.previewTarget.classList.add("hidden")
    this.previewTarget.classList.remove("flex")
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
    return (bytes / (1024 * 1024)).toFixed(1) + " MB"
  }
}
