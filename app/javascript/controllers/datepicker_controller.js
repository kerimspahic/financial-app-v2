import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display"]
  static values = { date: String }

  connect() {
    this.viewDate = this.dateValue ? new Date(this.dateValue + "T00:00:00") : new Date()
    this.today = new Date()
    this.today.setHours(0, 0, 0, 0)
    this.mode = "days"

    if (this.dateValue) {
      this.displayTarget.textContent = this.formatDisplay(new Date(this.dateValue + "T00:00:00"))
      this.displayTarget.classList.remove("text-text-muted")
      this.displayTarget.classList.add("text-text-primary")
    }

    // Grab refs before moving to body (escapes modal overflow/backdrop-filter)
    this.calendar = this.element.querySelector("[data-datepicker-el='calendar']")
    this.monthLabel = this.calendar.querySelector("[data-datepicker-el='monthLabel']")
    this.grid = this.calendar.querySelector("[data-datepicker-el='grid']")
    this.dayHeaders = this.calendar.querySelector("[data-datepicker-el='dayHeaders']")
    this.footer = this.calendar.querySelector("[data-datepicker-el='footer']")
    document.body.appendChild(this.calendar)

    // Event delegation on calendar (data-action won't work outside controller scope)
    this.calendar.addEventListener("click", this.handleCalendarClick)

    this.renderDays()
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleEscape)
    window.removeEventListener("scroll", this.reposition, true)
    window.removeEventListener("resize", this.reposition)
    this.calendar?.removeEventListener("click", this.handleCalendarClick)
    this.calendar?.remove()
  }

  // ── Calendar click delegation ──

  handleCalendarClick = (event) => {
    const target = event.target.closest("[data-action-name]")
    if (!target) return

    event.stopPropagation()
    const action = target.dataset.actionName

    switch (action) {
      case "prev": this.prev(); break
      case "next": this.next(); break
      case "showMonthPicker": this.showMonthPicker(); break
      case "showYearPicker": this.showYearPicker(); break
      case "selectDate": this.selectDate(target.dataset.date); break
      case "selectMonth": this.selectMonth(parseInt(target.dataset.month)); break
      case "selectYear": this.selectYear(parseInt(target.dataset.year)); break
      case "selectToday": this.selectToday(); break
    }
  }

  // ── Toggle ──

  toggle() {
    if (this.calendar.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.mode = "days"
    this.renderDays()
    this.positionCalendar()
    this.calendar.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.calendar.classList.remove("opacity-0", "scale-95")
      this.calendar.classList.add("opacity-100", "scale-100")
    })
    document.addEventListener("click", this.handleClickOutside)
    document.addEventListener("keydown", this.handleEscape)
    window.addEventListener("scroll", this.reposition, true)
    window.addEventListener("resize", this.reposition)
  }

  hide() {
    this.calendar.classList.add("opacity-0", "scale-95")
    this.calendar.classList.remove("opacity-100", "scale-100")
    setTimeout(() => {
      this.calendar.classList.add("hidden")
    }, 150)
    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleEscape)
    window.removeEventListener("scroll", this.reposition, true)
    window.removeEventListener("resize", this.reposition)
  }

  positionCalendar() {
    const trigger = this.displayTarget.closest("button")
    const rect = trigger.getBoundingClientRect()
    const calWidth = 296
    const calHeight = 380

    let top = rect.bottom + 8
    let left = rect.left

    if (top + calHeight > window.innerHeight) {
      top = rect.top - calHeight - 8
    }
    if (left + calWidth > window.innerWidth) {
      left = window.innerWidth - calWidth - 12
    }
    if (left < 12) left = 12

    this.calendar.style.position = "fixed"
    this.calendar.style.top = `${top}px`
    this.calendar.style.left = `${left}px`
  }

  reposition = () => {
    if (!this.calendar.classList.contains("hidden")) {
      this.positionCalendar()
    }
  }

  // ── Mode switching ──

  showMonthPicker() {
    this.mode = "months"
    this.renderMonths()
  }

  showYearPicker() {
    this.mode = "years"
    this.renderYears()
  }

  // ── Navigation ──

  prev() {
    if (this.mode === "days") {
      this.viewDate.setMonth(this.viewDate.getMonth() - 1)
      this.renderDays()
    } else if (this.mode === "months") {
      this.viewDate.setFullYear(this.viewDate.getFullYear() - 1)
      this.renderMonths()
    } else if (this.mode === "years") {
      this.viewDate.setFullYear(this.viewDate.getFullYear() - 12)
      this.renderYears()
    }
  }

  next() {
    if (this.mode === "days") {
      this.viewDate.setMonth(this.viewDate.getMonth() + 1)
      this.renderDays()
    } else if (this.mode === "months") {
      this.viewDate.setFullYear(this.viewDate.getFullYear() + 1)
      this.renderMonths()
    } else if (this.mode === "years") {
      this.viewDate.setFullYear(this.viewDate.getFullYear() + 12)
      this.renderYears()
    }
  }

  // ── Selections ──

  selectMonth(month) {
    this.viewDate.setMonth(month)
    this.mode = "days"
    this.renderDays()
  }

  selectYear(year) {
    this.viewDate.setFullYear(year)
    this.mode = "months"
    this.renderMonths()
  }

  selectDate(dateStr) {
    if (!dateStr) return
    this.#applyDate(dateStr)
    this.hide()
  }

  selectToday() {
    this.#applyDate(this.toISODate(this.today))
    this.hide()
  }

  // ── Renderers ──

  renderDays() {
    const year = this.viewDate.getFullYear()
    const month = this.viewDate.getMonth()

    this.monthLabel.innerHTML =
      `<button type="button" data-action-name="showMonthPicker" class="hover:text-primary-600 dark:hover:text-primary-400 transition-colors">${this.monthNamesShort[month]}</button>` +
      ` <button type="button" data-action-name="showYearPicker" class="hover:text-primary-600 dark:hover:text-primary-400 transition-colors">${year}</button>`

    this.dayHeaders.classList.remove("hidden")
    this.footer.classList.remove("hidden")

    const startDay = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const prevLastDay = new Date(year, month, 0).getDate()
    const selectedStr = this.dateValue
    const todayStr = this.toISODate(this.today)

    let html = ""

    for (let i = startDay - 1; i >= 0; i--) {
      html += `<div class="w-9 h-9 flex items-center justify-center text-sm text-text-muted/40 rounded-lg">${prevLastDay - i}</div>`
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = this.toISODate(new Date(year, month, day))
      const isSelected = dateStr === selectedStr
      const isToday = dateStr === todayStr

      let cls = "w-9 h-9 flex items-center justify-center text-sm rounded-lg cursor-pointer transition-all duration-150 "
      if (isSelected) {
        cls += "gradient-primary text-white font-semibold shadow-sm"
      } else if (isToday) {
        cls += "ring-1 ring-primary-500 text-primary-600 dark:text-primary-400 font-medium hover:bg-surface-hover"
      } else {
        cls += "text-text-primary hover:bg-surface-hover"
      }

      html += `<div class="${cls}" data-action-name="selectDate" data-date="${dateStr}">${day}</div>`
    }

    const totalCells = startDay + daysInMonth
    const remaining = totalCells <= 35 ? 35 - totalCells : 42 - totalCells
    for (let day = 1; day <= remaining; day++) {
      html += `<div class="w-9 h-9 flex items-center justify-center text-sm text-text-muted/40 rounded-lg">${day}</div>`
    }

    this.grid.className = "grid grid-cols-7 gap-0.5"
    this.grid.innerHTML = html
  }

  renderMonths() {
    const year = this.viewDate.getFullYear()
    const currentMonth = this.viewDate.getMonth()
    const todayMonth = this.today.getMonth()
    const todayYear = this.today.getFullYear()

    this.monthLabel.innerHTML =
      `<button type="button" data-action-name="showYearPicker" class="hover:text-primary-600 dark:hover:text-primary-400 transition-colors">${year}</button>`

    this.dayHeaders.classList.add("hidden")
    this.footer.classList.add("hidden")

    let html = ""
    for (let m = 0; m < 12; m++) {
      const isSelected = m === currentMonth
      const isToday = m === todayMonth && year === todayYear

      let cls = "h-10 flex items-center justify-center text-sm rounded-lg cursor-pointer transition-all duration-150 "
      if (isSelected) {
        cls += "gradient-primary text-white font-semibold shadow-sm"
      } else if (isToday) {
        cls += "ring-1 ring-primary-500 text-primary-600 dark:text-primary-400 font-medium hover:bg-surface-hover"
      } else {
        cls += "text-text-primary hover:bg-surface-hover"
      }

      html += `<div class="${cls}" data-action-name="selectMonth" data-month="${m}">${this.monthNamesShort[m]}</div>`
    }

    this.grid.className = "grid grid-cols-3 gap-2"
    this.grid.innerHTML = html
  }

  renderYears() {
    const currentYear = this.viewDate.getFullYear()
    const todayYear = this.today.getFullYear()
    const startYear = currentYear - 5

    this.monthLabel.textContent = `${startYear} \u2013 ${startYear + 11}`

    this.dayHeaders.classList.add("hidden")
    this.footer.classList.add("hidden")

    let html = ""
    for (let i = 0; i < 12; i++) {
      const year = startYear + i
      const isSelected = year === currentYear
      const isToday = year === todayYear

      let cls = "h-10 flex items-center justify-center text-sm rounded-lg cursor-pointer transition-all duration-150 "
      if (isSelected) {
        cls += "gradient-primary text-white font-semibold shadow-sm"
      } else if (isToday) {
        cls += "ring-1 ring-primary-500 text-primary-600 dark:text-primary-400 font-medium hover:bg-surface-hover"
      } else {
        cls += "text-text-primary hover:bg-surface-hover"
      }

      html += `<div class="${cls}" data-action-name="selectYear" data-year="${year}">${year}</div>`
    }

    this.grid.className = "grid grid-cols-3 gap-2"
    this.grid.innerHTML = html
  }

  // ── Private ──

  #applyDate(dateStr) {
    this.dateValue = dateStr
    this.inputTarget.value = dateStr
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))

    const date = new Date(dateStr + "T00:00:00")
    this.displayTarget.textContent = this.formatDisplay(date)
    this.displayTarget.classList.remove("text-text-muted")
    this.displayTarget.classList.add("text-text-primary")

    this.viewDate = new Date(date)
    this.renderDays()
  }

  formatDisplay(date) {
    return date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
  }

  toISODate(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  handleClickOutside = (event) => {
    if (!this.element.contains(event.target) && !this.calendar.contains(event.target)) {
      this.hide()
    }
  }

  handleEscape = (event) => {
    if (event.key === "Escape") {
      this.hide()
    }
  }

  get monthNamesShort() {
    return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  }
}
