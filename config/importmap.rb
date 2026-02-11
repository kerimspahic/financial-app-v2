# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chart.js", to: "chart.js"
pin "@tanstack/table-core", to: "https://cdn.jsdelivr.net/npm/@tanstack/table-core@8.21.3/+esm"
