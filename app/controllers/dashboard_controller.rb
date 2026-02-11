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
    @accounts = current_user.accounts.active
    @total_balance = @accounts.sum(:balance)

    # Net worth computation
    nw_accounts = current_user.accounts.active.included_in_net_worth
    @total_assets = nw_accounts.where(account_type: [ :checking, :savings, :cash, :investment, :property, :vehicle ].map { |t| Account.account_types[t] }).sum(:balance)
    @total_liabilities = nw_accounts.where(account_type: Account.account_types[:credit_card]).sum(:balance)
    @net_worth = @total_assets - @total_liabilities

    # Net worth change this month for stat cards
    start_of_month = Date.current.beginning_of_month
    account_ids = @accounts.map(&:id)
    if account_ids.any?
      month_start_snapshots = AccountBalanceSnapshot
        .where(account_id: account_ids)
        .where("date <= ?", start_of_month)
        .order(Arel.sql("account_id, date DESC"))
        .select("DISTINCT ON (account_id) account_id, balance")

      prior_balances = month_start_snapshots.index_by(&:account_id)
      prior_assets = 0
      prior_liabilities = 0
      @accounts.each do |acct|
        snap = prior_balances[acct.id]
        next unless snap
        if acct.asset?
          prior_assets += snap.balance
        elsif acct.liability?
          prior_liabilities += snap.balance
        end
      end
      prior_net_worth = prior_assets - prior_liabilities

      @net_worth_change = prior_net_worth.zero? ? nil : ((@net_worth - prior_net_worth) / prior_net_worth * 100).round(1)
      @assets_change = prior_assets.zero? ? nil : ((@total_assets - prior_assets) / prior_assets * 100).round(1)
      @liabilities_change = prior_liabilities.zero? ? nil : ((@total_liabilities - prior_liabilities) / prior_liabilities * 100).round(1)
    end

    @recent_transactions = current_user.transactions.recent.includes(:account, :category).limit(10)

    current_month = Date.current.month
    current_year = Date.current.year
    month_transactions = current_user.transactions.by_month(current_month, current_year)

    @monthly_income = month_transactions.income.sum(:amount)
    @monthly_expenses = month_transactions.expense.sum(:amount)
    @budgets = current_user.budgets.where(month: current_month, year: current_year).includes(:category)

    @upcoming_bills = current_user.bills.active
      .where("due_date >= ? AND due_date <= ?", Date.current, Date.current + 7.days)
      .order(:due_date).includes(:category).limit(5)

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
