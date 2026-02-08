import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    type: { type: String, default: "bar" },
    data: Object,
    options: { type: Object, default: {} }
  }

  connect() {
    this.loadChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  async loadChart() {
    let ChartModule
    try {
      ChartModule = await import("chart.js")
    } catch (error) {
      console.error("Failed to load Chart.js:", error)
      this.element.closest("[data-controller~=chart]")?.insertAdjacentHTML(
        "afterend",
        '<p class="text-sm text-text-muted text-center py-4">Chart unavailable</p>'
      )
      return
    }

    // UMD build sets window.Chart when loaded as a module
    const Chart = window.Chart || ChartModule.default || ChartModule.Chart
    if (!Chart) {
      console.error("Chart.js loaded but Chart constructor not found")
      return
    }

    const isDark = document.documentElement.classList.contains("dark")
    const style = getComputedStyle(document.documentElement)
    const textColor = isDark ? "#94a3b8" : "#64748b"
    const gridColor = isDark ? "rgba(255, 255, 255, 0.05)" : "rgba(0, 0, 0, 0.05)"

    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      animation: {
        duration: 800,
        easing: "easeOutQuart"
      },
      plugins: {
        legend: {
          display: this.typeValue !== "doughnut",
          labels: {
            color: textColor,
            font: { family: "system-ui, sans-serif", size: 12 },
            usePointStyle: true,
            pointStyle: "circle",
            padding: 16
          }
        },
        tooltip: {
          backgroundColor: isDark ? "rgba(15, 26, 23, 0.9)" : "rgba(255, 255, 255, 0.95)",
          titleColor: isDark ? "#f0fdf4" : "#0f172a",
          bodyColor: isDark ? "#94a3b8" : "#64748b",
          borderColor: isDark ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.1)",
          borderWidth: 1,
          padding: 12,
          cornerRadius: 12,
          displayColors: true,
          callbacks: {
            label: (context) => {
              let label = context.dataset.label || ""
              if (label) label += ": "
              const value = context.parsed.y !== undefined ? context.parsed.y : context.parsed
              label += new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: "USD",
                minimumFractionDigits: 0
              }).format(value)
              return label
            }
          }
        }
      }
    }

    // Add scales for non-doughnut charts
    if (this.typeValue !== "doughnut") {
      defaultOptions.scales = {
        y: {
          beginAtZero: true,
          ticks: {
            color: textColor,
            font: { size: 11 },
            callback: (value) => {
              return new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: "USD",
                minimumFractionDigits: 0,
                notation: "compact"
              }).format(value)
            }
          },
          grid: {
            color: gridColor,
            drawBorder: false
          }
        },
        x: {
          ticks: {
            color: textColor,
            font: { size: 11 }
          },
          grid: {
            display: false,
            drawBorder: false
          }
        }
      }
    }

    // Doughnut-specific options
    if (this.typeValue === "doughnut") {
      defaultOptions.cutout = "65%"
      defaultOptions.plugins.legend = {
        display: true,
        position: "right",
        labels: {
          color: textColor,
          font: { family: "system-ui, sans-serif", size: 11 },
          usePointStyle: true,
          pointStyle: "circle",
          padding: 12
        }
      }
    }

    // Read data once to apply enhancements
    const data = this.dataValue

    // Line chart enhancements
    if (this.typeValue === "line" && data.datasets) {
      data.datasets = data.datasets.map(ds => ({
        ...ds,
        tension: 0.4,
        fill: true,
        pointRadius: 3,
        pointHoverRadius: 6
      }))
    }

    // Bar chart enhancements
    if (this.typeValue === "bar" && data.datasets) {
      data.datasets = data.datasets.map(ds => ({
        ...ds,
        borderRadius: 6,
        borderSkipped: false
      }))
    }

    const mergedOptions = this.deepMerge(defaultOptions, this.optionsValue)

    this.chart = new Chart(this.element, {
      type: this.typeValue,
      data: data,
      options: mergedOptions
    })
  }

  deepMerge(target, source) {
    const result = { ...target }
    for (const key in source) {
      if (source[key] && typeof source[key] === "object" && !Array.isArray(source[key])) {
        result[key] = this.deepMerge(result[key] || {}, source[key])
      } else {
        result[key] = source[key]
      }
    }
    return result
  }
}
