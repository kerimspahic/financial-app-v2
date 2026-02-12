class ReportsController < ApplicationController
  require_permission "view_reports"

  def index
  end

  def by_payee
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    @payee_data = current_user.transactions
      .expense
      .included_in_reports
      .where(date: @start_date..@end_date)
      .where.not(payee: [ nil, "" ])
      .group(:payee)
      .select("payee, COUNT(*) as tx_count, SUM(amount) as total_spent, AVG(amount) as avg_amount")
      .order("total_spent DESC")

    @total_spent = @payee_data.sum(&:total_spent)

    @chart_data = {
      labels: @payee_data.first(15).map(&:payee),
      datasets: [ {
        label: "Total Spent",
        data: @payee_data.first(15).map { |p| p.total_spent.to_f },
        backgroundColor: chart_colors(15),
        borderRadius: 6
      } ]
    }
  end

  def by_tag
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    @tag_data = current_user.tags
      .joins(transaction_tags: :financial_transaction)
      .where(transactions: {
        transaction_type: :expense,
        exclude_from_reports: false,
        date: @start_date..@end_date
      })
      .group("tags.id, tags.name, tags.color")
      .select("tags.id, tags.name, tags.color, COUNT(transactions.id) as tx_count, SUM(transactions.amount) as total_spent")
      .order("total_spent DESC")

    @total_spent = @tag_data.sum(&:total_spent)

    tag_colors = @tag_data.map { |t| t.color.presence || "#6b7280" }

    @chart_data = {
      labels: @tag_data.map(&:name),
      datasets: [ {
        data: @tag_data.map { |t| t.total_spent.to_f },
        backgroundColor: tag_colors,
        borderWidth: 0
      } ]
    }
  end

  def trends
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 6.months.ago.beginning_of_month.to_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    @granularity = params[:granularity].presence || "monthly"
    @category_id = params[:category_id].presence

    base_scope = current_user.transactions.expense.included_in_reports.where(date: @start_date..@end_date)

    if @granularity == "weekly"
      date_trunc = "date_trunc('week', date)"
      format_label = ->(d) { "W#{d.strftime('%U')} #{d.strftime('%b %Y')}" }
    else
      date_trunc = "date_trunc('month', date)"
      format_label = ->(d) { d.strftime("%b %Y") }
    end

    # Total spending trend
    total_trend = base_scope
      .group(Arel.sql(date_trunc))
      .order(Arel.sql(date_trunc))
      .sum(:amount)

    labels = total_trend.keys.map { |d| format_label.call(d.to_date) }

    datasets = [ {
      label: "Total Expenses",
      data: total_trend.values.map(&:to_f),
      borderColor: "#ef4444",
      backgroundColor: "rgba(239, 68, 68, 0.1)"
    } ]

    # Category breakdown if requested
    if @category_id.present?
      category = current_user.categories.find(@category_id)
      cat_trend = base_scope
        .where(category_id: @category_id)
        .group(Arel.sql(date_trunc))
        .order(Arel.sql(date_trunc))
        .sum(:amount)

      cat_data = total_trend.keys.map { |k| cat_trend[k]&.to_f || 0 }
      datasets << {
        label: category.name,
        data: cat_data,
        borderColor: "#3b82f6",
        backgroundColor: "rgba(59, 130, 246, 0.1)"
      }
    end

    @chart_data = { labels: labels, datasets: datasets }
    @categories = current_user.categories.expense.order(:name)
  end

  def cash_flow
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 6.months.ago.beginning_of_month.to_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    date_trunc = "date_trunc('month', date)"

    base_scope = current_user.transactions.included_in_reports.where(date: @start_date..@end_date)

    income_by_month = base_scope.income
      .group(Arel.sql(date_trunc))
      .order(Arel.sql(date_trunc))
      .sum(:amount)

    expense_by_month = base_scope.expense
      .group(Arel.sql(date_trunc))
      .order(Arel.sql(date_trunc))
      .sum(:amount)

    all_months = (income_by_month.keys + expense_by_month.keys).uniq.sort
    labels = all_months.map { |d| d.to_date.strftime("%b %Y") }

    income_data = all_months.map { |m| income_by_month[m]&.to_f || 0 }
    expense_data = all_months.map { |m| expense_by_month[m]&.to_f || 0 }
    net_data = all_months.each_with_index.map { |_, i| income_data[i] - expense_data[i] }

    @monthly_data = all_months.each_with_index.map do |m, i|
      {
        month: m.to_date.strftime("%b %Y"),
        income: income_data[i],
        expenses: expense_data[i],
        net: net_data[i]
      }
    end

    @total_income = income_data.sum
    @total_expenses = expense_data.sum
    @total_net = @total_income - @total_expenses

    @chart_data = {
      labels: labels,
      datasets: [
        {
          label: "Income",
          data: income_data,
          backgroundColor: "rgba(34, 197, 94, 0.7)",
          borderColor: "#22c55e",
          borderWidth: 1,
          order: 2
        },
        {
          label: "Expenses",
          data: expense_data.map { |v| v * -1 },
          backgroundColor: "rgba(239, 68, 68, 0.7)",
          borderColor: "#ef4444",
          borderWidth: 1,
          order: 2
        },
        {
          label: "Net Flow",
          data: net_data,
          type: "line",
          borderColor: "#3b82f6",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          borderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6,
          fill: false,
          order: 1
        }
      ]
    }
  end

  def comparisons
    @period1_start = params[:period1_start].present? ? Date.parse(params[:period1_start]) : Date.current.beginning_of_month
    @period1_end = params[:period1_end].present? ? Date.parse(params[:period1_end]) : Date.current.end_of_month
    @period2_start = params[:period2_start].present? ? Date.parse(params[:period2_start]) : 1.month.ago.beginning_of_month.to_date
    @period2_end = params[:period2_end].present? ? Date.parse(params[:period2_end]) : 1.month.ago.end_of_month.to_date

    base_scope = current_user.transactions.expense.included_in_reports

    period1_by_cat = base_scope
      .where(date: @period1_start..@period1_end)
      .joins(:category)
      .group("categories.name")
      .sum(:amount)

    period2_by_cat = base_scope
      .where(date: @period2_start..@period2_end)
      .joins(:category)
      .group("categories.name")
      .sum(:amount)

    all_categories = (period1_by_cat.keys + period2_by_cat.keys).uniq.sort
    @period1_label = format_period_label(@period1_start, @period1_end)
    @period2_label = format_period_label(@period2_start, @period2_end)

    @comparison_data = all_categories.map do |cat_name|
      p1 = period1_by_cat[cat_name]&.to_f || 0
      p2 = period2_by_cat[cat_name]&.to_f || 0
      change = p2 > 0 ? ((p1 - p2) / p2 * 100).round(1) : (p1 > 0 ? 100.0 : 0.0)
      { category: cat_name, period1: p1, period2: p2, change: change }
    end

    @period1_total = @comparison_data.sum { |d| d[:period1] }
    @period2_total = @comparison_data.sum { |d| d[:period2] }
    @total_change = @period2_total > 0 ? ((@period1_total - @period2_total) / @period2_total * 100).round(1) : 0.0

    @chart_data = {
      labels: all_categories,
      datasets: [
        {
          label: @period1_label,
          data: all_categories.map { |c| period1_by_cat[c]&.to_f || 0 },
          backgroundColor: "rgba(59, 130, 246, 0.7)",
          borderColor: "#3b82f6",
          borderWidth: 1
        },
        {
          label: @period2_label,
          data: all_categories.map { |c| period2_by_cat[c]&.to_f || 0 },
          backgroundColor: "rgba(168, 85, 247, 0.7)",
          borderColor: "#a855f7",
          borderWidth: 1
        }
      ]
    }
  end

  private

  def chart_colors(count)
    palette = [
      "#3b82f6", "#ef4444", "#22c55e", "#f59e0b", "#a855f7",
      "#06b6d4", "#ec4899", "#14b8a6", "#f97316", "#6366f1",
      "#84cc16", "#e11d48", "#0ea5e9", "#8b5cf6", "#10b981"
    ]
    Array.new(count) { |i| palette[i % palette.size] }
  end

  def format_period_label(start_date, end_date)
    if start_date.month == end_date.month && start_date.year == end_date.year
      start_date.strftime("%b %Y")
    else
      "#{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}"
    end
  end
end
