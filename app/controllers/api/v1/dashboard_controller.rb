module Api
  module V1
    class DashboardController < BaseController
      def index
        accounts = current_user.accounts
        current_month = Date.current.month
        current_year = Date.current.year
        month_transactions = current_user.transactions.by_month(current_month, current_year)

        render json: {
          total_balance: accounts.sum(:balance),
          monthly_income: month_transactions.income.sum(:amount),
          monthly_expenses: month_transactions.expense.sum(:amount),
          accounts: accounts,
          recent_transactions: current_user.transactions.recent.includes(:account, :category).limit(10),
          budgets: current_user.budgets.where(month: current_month, year: current_year).includes(:category).map { |b|
            b.as_json(include: :category).merge(spent: b.spent, remaining: b.remaining, percent_used: b.percent_used)
          }
        }
      end
    end
  end
end
