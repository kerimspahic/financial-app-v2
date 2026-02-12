import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropZone", "preview", "fileCount", "errorMessage"]
  static values = {
    maxFiles: { type: Number, default: 5 },
    maxSize: { type: Number, default: 10485760 }, // 10MB
    allowedTypes: { type: Array, default: ["image/jpeg", "image/png", "image/webp", "application/pdf"] }
  }

  connect() {
    this.files = []
    this.setupDropZone()
  }

  setupDropZone() {
    if (!this.hasDropZoneTarget) return

    const zone = this.dropZoneTarget

    zone.addEventListener("dragover", (e) => {
      e.preventDefault()
      e.stopPropagation()
      zone.classList.add("border-primary-500", "bg-primary-50/10")
      zone.classList.remove("border-glass-border")
    })

    zone.addEventListener("dragleave", (e) => {
      e.preventDefault()
      e.stopPropagation()
      zone.classList.remove("border-primary-500", "bg-primary-50/10")
      zone.classList.add("border-glass-border")
    })

    zone.addEventListener("drop", (e) => {
      e.preventDefault()
      e.stopPropagation()
      zone.classList.remove("border-primary-500", "bg-primary-50/10")
      zone.classList.add("border-glass-border")

      const droppedFiles = Array.from(e.dataTransfer.files)
      this.addFiles(droppedFiles)
    })
  }

  selectFiles() {
    this.inputTarget.click()
  }

  handleFileSelect(event) {
    const selectedFiles = Array.from(event.target.files)
    this.addFiles(selectedFiles)
    // Reset the input so re-selecting the same file works
    this.inputTarget.value = ""
  }

  addFiles(newFiles) {
    this.clearError()

    for (const file of newFiles) {
      if (this.files.length >= this.maxFilesValue) {
        this.showError(`Maximum ${this.maxFilesValue} files allowed`)
        break
      }

      if (!this.allowedTypesValue.includes(file.type)) {
        this.showError(`${file.name}: Invalid file type. Use JPEG, PNG, WebP, or PDF.`)
        continue
      }

      if (file.size > this.maxSizeValue) {
        this.showError(`${file.name}: File too large. Maximum 10MB.`)
        continue
      }

      this.files.push(file)
    }

    this.updatePreview()
    this.syncInputFiles()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)
    this.updatePreview()
    this.syncInputFiles()
  }

  syncInputFiles() {
    // Create a new DataTransfer to hold our file list
    const dt = new DataTransfer()
    this.files.forEach(file => dt.items.add(file))
    this.inputTarget.files = dt.files
  }

  updatePreview() {
    if (!this.hasPreviewTarget) return

    if (this.hasFileCountTarget) {
      this.fileCountTarget.textContent = this.files.length > 0
        ? `${this.files.length}/${this.maxFilesValue} files`
        : ""
    }

    this.previewTarget.innerHTML = ""

    this.files.forEach((file, index) => {
      const wrapper = document.createElement("div")
      wrapper.className = "relative group rounded-xl overflow-hidden border border-glass-border glass w-20 h-20 flex items-center justify-center"

      if (file.type.startsWith("image/")) {
        const img = document.createElement("img")
        img.className = "w-full h-full object-cover"
        img.src = URL.createObjectURL(file)
        wrapper.appendChild(img)
      } else {
        // PDF icon
        const icon = document.createElement("div")
        icon.className = "flex flex-col items-center gap-1"
        icon.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8 text-danger-500" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
          </svg>
          <span class="text-[9px] text-text-muted font-medium">PDF</span>
        `
        wrapper.appendChild(icon)
      }

      // Remove button
      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.className = "absolute -top-0.5 -right-0.5 w-5 h-5 rounded-full bg-danger-500 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-sm"
      removeBtn.dataset.index = index
      removeBtn.dataset.action = "click->receipt-upload#removeFile"
      removeBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>`
      wrapper.appendChild(removeBtn)

      // File name tooltip
      const nameLabel = document.createElement("div")
      nameLabel.className = "absolute bottom-0 left-0 right-0 bg-black/60 text-white text-[8px] px-1 py-0.5 truncate text-center"
      nameLabel.textContent = file.name
      wrapper.appendChild(nameLabel)

      this.previewTarget.appendChild(wrapper)
    })
  }

  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove("hidden")
    }
  }

  clearError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.classList.add("hidden")
      this.errorMessageTarget.textContent = ""
    }
  }
}
