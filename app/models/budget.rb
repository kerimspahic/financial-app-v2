class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true
  validates :category_id, uniqueness: { scope: [ :user_id, :month, :year ], message: "already has a budget for this month" }
  validate :category_belongs_to_user

  def spent
    @spent ||= category.transactions.expense.by_month(month, year).where(user: user).sum(:amount)
  end

  def remaining
    amount - spent
  end

  def percent_used
    return 0 if amount.zero?
    ((spent / amount) * 100).round(1)
  end

  private

  def category_belongs_to_user
    return unless user_id && category_id
    errors.add(:category, "is not valid") unless Category.exists?(id: category_id, user_id: user_id)
  end
end
