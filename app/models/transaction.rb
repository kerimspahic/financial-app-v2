class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :category

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true
  validates :date, presence: true

  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :by_month, ->(month, year) { where(date: Date.new(year, month)..Date.new(year, month).end_of_month) }
end
