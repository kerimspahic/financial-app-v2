module ApplicationHelper
  include Heroicon::ApplicationHelper

  ACCOUNT_COLORS = {
    checking: { bg: "bg-blue-50 dark:bg-blue-900/20", text: "text-blue-600 dark:text-blue-400", icon_bg: "bg-blue-500" },
    savings: { bg: "bg-emerald-50 dark:bg-emerald-900/20", text: "text-emerald-600 dark:text-emerald-400", icon_bg: "bg-emerald-500" },
    credit_card: { bg: "bg-red-50 dark:bg-red-900/20", text: "text-red-600 dark:text-red-400", icon_bg: "bg-red-500" },
    cash: { bg: "bg-amber-50 dark:bg-amber-900/20", text: "text-amber-600 dark:text-amber-400", icon_bg: "bg-amber-500" },
    investment: { bg: "bg-purple-50 dark:bg-purple-900/20", text: "text-purple-600 dark:text-purple-400", icon_bg: "bg-purple-500" },
    property: { bg: "bg-teal-50 dark:bg-teal-900/20", text: "text-teal-600 dark:text-teal-400", icon_bg: "bg-teal-500" },
    vehicle: { bg: "bg-sky-50 dark:bg-sky-900/20", text: "text-sky-600 dark:text-sky-400", icon_bg: "bg-sky-500" }
  }.freeze

  ACCOUNT_ICONS = {
    checking: "building-library",
    savings: "banknotes",
    credit_card: "credit-card",
    cash: "currency-dollar",
    investment: "chart-bar-square",
    property: "home-modern",
    vehicle: "truck"
  }.freeze

  def account_type_color(account_type)
    ACCOUNT_COLORS[account_type.to_sym] || { bg: "bg-surface-alt", text: "text-text-primary", icon_bg: "bg-primary-500" }
  end

  def account_type_icon(account_type)
    ACCOUNT_ICONS[account_type.to_sym] || "building-library"
  end

  def formatted_amount(transaction)
    prefix = transaction.income? ? "+" : "-"
    "#{prefix}#{number_to_currency(transaction.amount)}"
  end

  def amount_color_class(transaction)
    transaction.income? ? "text-success-600" : "text-danger-600"
  end

  def deadline_color(savings_goal)
    return "text-text-primary" unless savings_goal.deadline.present?
    return "text-success-600" if savings_goal.progress_percentage >= 100

    if savings_goal.days_remaining && savings_goal.days_remaining < 0
      "text-danger-600"
    elsif savings_goal.on_track?
      "text-success-600"
    else
      "text-warning-600"
    end
  end

  def converted_balance_display(account, base_currency = "USD")
    return nil if account.currency == base_currency

    begin
      result = ExchangeRateService.convert(amount: account.balance, from: account.currency, to: base_currency)
      "(~#{number_to_currency(result[:converted_amount])} #{base_currency})"
    rescue ExchangeRateService::ApiError
      nil
    end
  end
end
