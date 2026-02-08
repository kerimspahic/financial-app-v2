# FinanceApp

A personal budgeting application built with Rails 8. Track accounts, transactions, budgets, and spending categories. Includes a full JSON API for future mobile app integration.

## Tech Stack

- **Ruby** 3.4.2 / **Rails** 8.1.2
- **PostgreSQL** - database
- **Hotwire** (Turbo + Stimulus) - frontend interactivity
- **Tailwind CSS** 4 - styling
- **Devise** + **devise-jwt** - authentication (session-based for web, JWT for API)

## Features

- **Dashboard** - balance overview, monthly income/expenses, budget progress
- **Accounts** - manage checking, savings, credit card, cash, and investment accounts
- **Transactions** - log income, expenses, and transfers with filtering
- **Categories** - organize transactions by income/expense categories (14 defaults auto-created)
- **Budgets** - set monthly spending limits per category with progress tracking
- **REST API** - versioned JSON API at `/api/v1/` with JWT authentication

## Setup

### Prerequisites

- Ruby 3.4+
- PostgreSQL
- Node.js 20+

### Installation

```bash
git clone <repo-url>
cd financial-app
bundle install
bin/rails db:create db:migrate db:seed
```

### Run the app

```bash
bin/dev
```

Visit `http://localhost:3000`.

### Demo account

- **Email:** demo@example.com
- **Password:** password123

## API

All API endpoints are under `/api/v1/` and require a JWT token (sent via `Authorization: Bearer <token>` header).

### Authentication

```
POST   /api/v1/auth/sign_in   - Sign in (returns JWT)
POST   /api/v1/auth/sign_up   - Register
DELETE /api/v1/auth/sign_out  - Sign out (revokes JWT)
```

### Resources

```
GET/POST           /api/v1/accounts
GET/PATCH/DELETE   /api/v1/accounts/:id
GET/POST           /api/v1/transactions
GET/PATCH/DELETE   /api/v1/transactions/:id
GET/POST           /api/v1/categories
PATCH/DELETE       /api/v1/categories/:id
GET/POST           /api/v1/budgets
PATCH/DELETE       /api/v1/budgets/:id
GET                /api/v1/dashboard
```

## Tests

```bash
bin/rails test
```
