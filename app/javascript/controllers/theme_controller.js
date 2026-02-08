import { Controller } from "@hotwired/stimulus"

const VALID_COLORS = ["green", "blue", "purple", "rose", "amber", "cyan"]
const VALID_THEMES = ["light", "dark", "system"]
const COLOR_CLASSES = VALID_COLORS.map(c => `color-${c}`)

export default class extends Controller {
  static targets = ["icon", "label"]
  static values = {
    themeMode: { type: String, default: "" },
    colorMode: { type: String, default: "" }
  }

  connect() {
    this.syncFromServer()
    this.applyTheme()
    this.applyColor()
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQuery.addEventListener("change", this.handleSystemChange)
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.handleSystemChange)
  }

  // Sync server-provided preferences to localStorage
  syncFromServer() {
    if (this.themeModeValue) {
      localStorage.setItem("theme", this.themeModeValue)
    }
    if (this.colorModeValue) {
      localStorage.setItem("colorMode", this.colorModeValue)
    }
  }

  // --- Theme mode (light/dark/system) ---

  toggle() {
    const current = this.currentTheme
    const next = current === "light" ? "dark" : current === "dark" ? "system" : "light"
    this.setTheme(next)
  }

  light() { this.setTheme("light") }
  dark() { this.setTheme("dark") }
  system() { this.setTheme("system") }

  setTheme(theme) {
    localStorage.setItem("theme", theme)
    this.applyTheme()
    this.persistToServer({ theme_mode: theme })
  }

  applyTheme() {
    const theme = this.currentTheme
    const isDark = theme === "dark" || (theme === "system" && this.systemPrefersDark)

    document.documentElement.classList.toggle("dark", isDark)
    this.updateIndicator(theme)
  }

  // --- Color mode (green/blue/purple) ---

  setColor(event) {
    const color = event.params?.color || event.currentTarget.dataset.themeColorParam
    if (!color || !VALID_COLORS.includes(color)) return

    localStorage.setItem("colorMode", color)
    this.applyColor()
    this.persistToServer({ color_mode: color })
  }

  applyColor() {
    const color = this.currentColor
    const root = document.documentElement
    COLOR_CLASSES.forEach(cls => root.classList.remove(cls))
    if (color !== "green") {
      root.classList.add(`color-${color}`)
    }
  }

  // --- Helpers ---

  updateIndicator(theme) {
    if (this.hasIconTarget) {
      const icons = { light: "sun", dark: "moon", system: "computer-desktop" }
      this.iconTarget.dataset.icon = icons[theme] || "sun"
    }
    if (this.hasLabelTarget) {
      const labels = { light: "Light", dark: "Dark", system: "System" }
      this.labelTarget.textContent = labels[theme] || "Light"
    }
  }

  handleSystemChange = () => {
    if (this.currentTheme === "system") {
      this.applyTheme()
    }
  }

  get currentTheme() {
    const theme = localStorage.getItem("theme")
    return VALID_THEMES.includes(theme) ? theme : "system"
  }

  get currentColor() {
    const color = localStorage.getItem("colorMode")
    return VALID_COLORS.includes(color) ? color : "green"
  }

  get systemPrefersDark() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
  }

  // Only persist to DB when a user is signed in (server-provided values present)
  get isSignedIn() {
    return this.themeModeValue !== "" || this.colorModeValue !== ""
  }

  persistToServer(params) {
    if (!this.isSignedIn) return
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    if (!csrfToken) return

    fetch("/settings/theme", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify(params)
    }).catch(() => {})
  }
}
