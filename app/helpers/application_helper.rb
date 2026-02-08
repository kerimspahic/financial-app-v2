module ApplicationHelper
  include Heroicon::ApplicationHelper

  ACCOUNT_COLORS = {
    checking: { bg: "bg-blue-50 dark:bg-blue-900/20", text: "text-blue-600 dark:text-blue-400", icon_bg: "bg-blue-500" },
    savings: { bg: "bg-emerald-50 dark:bg-emerald-900/20", text: "text-emerald-600 dark:text-emerald-400", icon_bg: "bg-emerald-500" },
    credit_card: { bg: "bg-red-50 dark:bg-red-900/20", text: "text-red-600 dark:text-red-400", icon_bg: "bg-red-500" },
    cash: { bg: "bg-amber-50 dark:bg-amber-900/20", text: "text-amber-600 dark:text-amber-400", icon_bg: "bg-amber-500" },
    investment: { bg: "bg-purple-50 dark:bg-purple-900/20", text: "text-purple-600 dark:text-purple-400", icon_bg: "bg-purple-500" }
  }.freeze

  ACCOUNT_ICONS = {
    checking: "building-library",
    savings: "banknotes",
    credit_card: "credit-card",
    cash: "currency-dollar",
    investment: "chart-bar-square"
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
end
