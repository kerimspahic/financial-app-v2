# FinanceApp - Future Roadmap

## Phase 1: Foundation

### 1A - Dynamic User Settings
- [x] UserPreference model (theme mode, color mode, per page)
- [x] Settings page UI
- [ ] Expand preferences (currency, date format, default account, budget thresholds)
- [ ] Replace all hardcoded values with user preferences
- [x] API endpoint for settings

### 1B - Configurable Roles & Permissions
- [ ] Permission model (granular keys like `view_accounts`, `manage_users`)
- [ ] Role model with admin UI to create custom roles
- [ ] Permission matrix UI (checkbox grid: roles x permissions)
- [ ] UserRole assignment
- [ ] Authorization checks on all controllers (web + API)
- [ ] Default roles: admin, user, viewer
- [ ] Admin panel for managing users and roles

### 1C - Design System + Dark Mode ✅
- [x] ViewComponent gem integration
- [x] Reusable components: Button, Card, Modal, Badge, Table, Input, Alert, ProgressBar, Dropdown, Avatar, PageHeader, EmptyState, StatCard
- [x] Design tokens (CSS custom properties via Tailwind 4 `@theme` directive)
- [x] Dark/light/system theme toggle with persistence (localStorage)
- [x] Heroicons integration
- [x] Stimulus controllers: theme, modal, dropdown, alert, counter, toast, chart, sidebar
- [x] Glassmorphism design (`.glass` / `.glass-strong` utilities, animated gradient background)
- [x] 6 color themes (green, blue, purple, rose, amber, cyan)
- [x] Animations (card-entrance, fade-up, slide-in-right, progress-fill, hover-lift)
- [x] Refactor all existing views to use components

---

## Phase 2: Core Financial Features

### 2A - Recurring Transactions
- [ ] RecurringTransaction model (frequency: daily/weekly/biweekly/monthly/quarterly/yearly)
- [ ] Background job to auto-create transactions daily
- [ ] Skip, pause, resume actions
- [ ] CRUD UI + API endpoints
- [ ] Schedule config in `recurring.yml`

### 2B - Savings Goals
- [ ] SavingsGoal model (target amount, current amount, deadline)
- [ ] SavingsContribution model (audit trail)
- [ ] Contribute/withdraw actions
- [ ] Progress tracking (percent complete, on track, days remaining)
- [ ] Milestone detection (25%, 50%, 75%, 100%)
- [ ] Dashboard widget
- [ ] CRUD UI + API endpoints

### 2C - Bill Reminders
- [ ] Bill model (name, amount, due date, frequency, reminder days before)
- [ ] BillPayment model (tracks each payment)
- [ ] Mark as paid → auto-creates a transaction
- [ ] Overdue/upcoming status tracking
- [ ] Background job for reminders
- [ ] Dashboard widget showing upcoming bills
- [ ] CRUD UI + API endpoints

---

## Phase 3: Notification System

- [ ] Notification model (title, body, type, read/unread, actionable URL)
- [ ] NotificationPreference model (per type: in-app on/off, email on/off)
- [ ] NotificationService (central service for creating + delivering)
- [ ] NotificationMailer (email delivery)
- [ ] Real-time in-app via Turbo Streams + Action Cable
- [ ] Notification bell with unread count in nav
- [ ] Notification types:
  - [ ] Budget warning (approaching limit)
  - [ ] Budget exceeded
  - [ ] Bill reminder (upcoming due date)
  - [ ] Bill overdue
  - [ ] Savings goal milestone
  - [ ] Monthly financial summary
  - [ ] Weekly spending digest
- [ ] Background jobs: BudgetAlertJob, MonthlySummaryJob, WeeklyDigestJob
- [ ] User preferences UI (which notifications, which channels)
- [ ] API endpoints for notifications

---

## Phase 4: Reports & Exports

- [ ] Reports service objects (MonthlyReport, YearlyReport, TrendReport)
- [x] Chart.js integration via importmap (pinned, with Stimulus chart controller)
- [ ] Monthly report: income/expenses by category, budget vs actual
- [ ] Yearly report: 12-month breakdown, savings rate, net worth trend
- [ ] Trend analysis: spending/income over custom date ranges
- [ ] CSV export for transactions
- [ ] PDF report generation (prawn gem)
- [ ] Date range filter component
- [ ] Reports page with chart visualizations
- [ ] API endpoints returning report data as JSON

---

## Future Ideas
- [ ] Multi-currency support with exchange rates
- [ ] Shared household/family budgets (multi-tenant)
- [ ] Bank account sync (Plaid API integration)
- [ ] Receipt scanning (image upload + OCR)
- [ ] Financial insights / AI-powered spending analysis
- [ ] Mobile app (React Native / Flutter using the API)
- [ ] Two-factor authentication
- [ ] Data import from other apps (CSV/OFX/QIF)
- [ ] Debt payoff tracker (snowball/avalanche methods)
- [ ] Net worth tracking over time
- [ ] Custom dashboard widgets (drag & drop layout)
- [ ] Tags/labels on transactions (in addition to categories)
- [ ] Split transactions (one purchase across multiple categories)
- [ ] Investment portfolio tracking (stocks, crypto, assets)
- [ ] Loan & mortgage tracker with amortization schedule
- [ ] Cash flow forecasting / projections
- [ ] Financial calendar view (bills, recurring, goals on a calendar)
- [ ] Spending challenges / gamification (streaks, achievements)
- [ ] Audit log / activity history for all changes
- [ ] Transaction attachments (receipts, documents, photos)
- [ ] Auto-copy budgets month to month
- [ ] Budget templates (save & reuse budget presets)
- [ ] Quick-add transaction templates (one-tap for frequent purchases)
- [ ] Wishlist / planned purchases tracker
- [ ] Financial health score (computed from spending habits)
- [ ] Month vs month / year vs year spending comparisons
- [ ] Tax category tagging for tax season
- [ ] Annual tax summary report
- [ ] Subscription tracker (detect & flag recurring charges)
- [ ] Shared expense splitting (like Splitwise)
- [ ] Credit score tracking integration
- [ ] Multi-language support (i18n)
- [ ] PWA install support (mobile-like experience without app store)
- [ ] Onboarding wizard for new users
- [ ] API documentation (Swagger/OpenAPI)
- [x] API rate limiting (Rack::Attack on auth endpoints)
- [ ] Webhook integrations (trigger external services)
- [ ] Full account data backup & export

---

## Tech Stack for Upgrades
| Need | Solution |
|------|----------|
| UI Components | `view_component` gem ✅ |
| Icons | `heroicon` gem ✅ |
| PDF Generation | `prawn` + `prawn-table` gems |
| Charts | Chart.js via importmap ✅ |
| Background Jobs | Solid Queue (already configured) |
| Real-time | Action Cable + Turbo Streams (already configured) |
| Authorization | Custom Authorizable concern (dynamic, DB-backed) |
