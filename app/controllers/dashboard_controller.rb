class DashboardController < ApplicationController
  CHART_COLORS = {
    income: { bg: "rgba(34, 197, 94, 0.7)", border: "rgb(34, 197, 94)" },
    expense: { bg: "rgba(239, 68, 68, 0.7)", border: "rgb(239, 68, 68)" },
    net: { bg: "rgba(59, 130, 246, 0.1)", border: "rgb(59, 130, 246)" },
    categories: [
      "rgba(239, 68, 68, 0.8)", "rgba(249, 115, 22, 0.8)", "rgba(245, 158, 11, 0.8)",
      "rgba(34, 197, 94, 0.8)", "rgba(59, 130, 246, 0.8)", "rgba(168, 85, 247, 0.8)",
      "rgba(236, 72, 153, 0.8)", "rgba(20, 184, 166, 0.8)"
    ]
  }.freeze

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

    load_monthly_totals
    @monthly_chart_data = monthly_chart_data
    @category_breakdown_data = category_breakdown_data
    @cash_flow_data = cash_flow_data
  end

  private

  def load_monthly_totals
    range_start = 5.months.ago.beginning_of_month.to_date
    range_end = Date.current.end_of_month

    @monthly_totals = current_user.transactions
      .where(date: range_start..range_end)
      .group(:transaction_type, Arel.sql("DATE_TRUNC('month', date)"))
      .sum(:amount)
  end

  def monthly_amount_for(date, type)
    truncated = date.beginning_of_month.in_time_zone.utc
    (@monthly_totals[[ type.to_s, truncated ]] || 0).to_f
  end

  def months_range
    @months_range ||= 5.downto(0).map { |n| n.months.ago.beginning_of_month.to_date }
  end

  def monthly_chart_data
    {
      labels: months_range.map { |d| d.strftime("%b %Y") },
      datasets: [
        {
          label: "Income",
          data: months_range.map { |d| monthly_amount_for(d, :income) },
          backgroundColor: CHART_COLORS[:income][:bg],
          borderColor: CHART_COLORS[:income][:border],
          borderWidth: 2
        },
        {
          label: "Expenses",
          data: months_range.map { |d| monthly_amount_for(d, :expense) },
          backgroundColor: CHART_COLORS[:expense][:bg],
          borderColor: CHART_COLORS[:expense][:border],
          borderWidth: 2
        }
      ]
    }
  end

  def category_breakdown_data
    month_start = Date.current.beginning_of_month
    month_end = Date.current.end_of_month

    totals_by_category = current_user.transactions
      .where(transaction_type: :expense, date: month_start..month_end)
      .joins(:category)
      .group("categories.name")
      .sum(:amount)

    category_totals = totals_by_category
      .select { |_, total| total.positive? }
      .map { |name, total| { name: name, total: total } }

    {
      labels: category_totals.map { |c| c[:name] },
      datasets: [ {
        data: category_totals.map { |c| c[:total] },
        backgroundColor: CHART_COLORS[:categories].first(category_totals.size),
        borderWidth: 0,
        hoverOffset: 8
      } ]
    }
  end

  def cash_flow_data
    income_data = months_range.map { |d| monthly_amount_for(d, :income) }
    expense_data = months_range.map { |d| monthly_amount_for(d, :expense) }
    net_data = income_data.zip(expense_data).map { |i, e| i - e }

    {
      labels: months_range.map { |d| d.strftime("%b %Y") },
      datasets: [
        {
          label: "Net Cash Flow",
          data: net_data,
          borderColor: CHART_COLORS[:net][:border],
          backgroundColor: CHART_COLORS[:net][:bg],
          borderWidth: 2
        }
      ]
    }
  end
end
