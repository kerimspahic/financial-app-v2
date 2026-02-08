class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :category

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true
  validates :date, presence: true
  validate :account_belongs_to_user
  validate :category_belongs_to_user

  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :by_month, ->(month, year) { where(date: Date.new(year, month)..Date.new(year, month).end_of_month) }

  private

  def account_belongs_to_user
    return unless user_id && account_id
    errors.add(:account, "is not valid") unless Account.exists?(id: account_id, user_id: user_id)
  end

  def category_belongs_to_user
    return unless user_id && category_id
    errors.add(:category, "is not valid") unless Category.exists?(id: category_id, user_id: user_id)
  end
end
