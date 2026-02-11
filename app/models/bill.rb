class Bill < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :account, optional: true
  has_many :bill_payments, dependent: :destroy

  enum :frequency, { weekly: 0, biweekly: 1, monthly: 2, quarterly: 3, yearly: 4 }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :frequency, presence: true

  scope :active, -> { where(active: true) }
  scope :upcoming, -> { active.where("due_date >= ?", Date.current).order(:due_date) }
  scope :due_soon, ->(days = 7) { active.where("due_date >= ? AND due_date <= ?", Date.current, Date.current + days.days).order(:due_date) }

  def next_due_date
    date = due_date
    date = advance_date(date) while date < Date.current || paid_for_period?(date)
    date
  end

  def paid_this_period?
    paid_for_period?(next_due_date)
  end

  def days_until_due
    (next_due_date - Date.current).to_i
  end

  def status
    if paid_this_period?
      :paid
    elsif next_due_date < Date.current
      :overdue
    elsif days_until_due <= 7
      :due_soon
    else
      :upcoming
    end
  end

  def annual_cost
    multiplier = case frequency
    when "weekly" then 52
    when "biweekly" then 26
    when "monthly" then 12
    when "quarterly" then 4
    when "yearly" then 1
    else 12
    end
    amount * multiplier
  end

  def status_variant
    case status
    when :paid then :success
    when :overdue then :danger
    when :due_soon then :warning
    when :upcoming then :neutral
    else :neutral
    end
  end

  private

  def advance_date(date)
    case frequency
    when "weekly" then date + 1.week
    when "biweekly" then date + 2.weeks
    when "monthly" then date + 1.month
    when "quarterly" then date + 3.months
    when "yearly" then date + 1.year
    else date + 1.month
    end
  end

  def paid_for_period?(date)
    period_start, period_end = period_range(date)
    bill_payments.where(paid_date: period_start..period_end).exists?
  end

  def period_range(date)
    case frequency
    when "weekly"
      [ date.beginning_of_week, date.end_of_week ]
    when "biweekly"
      [ date - 6.days, date + 7.days ]
    when "monthly"
      [ date.beginning_of_month, date.end_of_month ]
    when "quarterly"
      [ date.beginning_of_quarter, date.end_of_quarter ]
    when "yearly"
      [ date.beginning_of_year, date.end_of_year ]
    else
      [ date.beginning_of_month, date.end_of_month ]
    end
  end
end
