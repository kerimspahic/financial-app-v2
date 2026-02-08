class DashboardController < ApplicationController
  def index
    @accounts = current_user.accounts
    @total_balance = @accounts.sum(:balance)
    @recent_transactions = current_user.transactions.recent.includes(:account, :category).limit(10)

    current_month = Date.current.month
    current_year = Date.current.year
    month_transactions = current_user.transactions.by_month(current_month, current_year)

    @monthly_income = month_transactions.income.sum(:amount)
    @monthly_expenses = month_transactions.expense.sum(:amount)
    @budgets = current_user.budgets.where(month: current_month, year: current_year).includes(:category)
  end
end
