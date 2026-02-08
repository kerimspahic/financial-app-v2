class RecurringTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :category

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }
  enum :frequency, { daily: 0, weekly: 1, biweekly: 2, monthly: 3, quarterly: 4, yearly: 5 }

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true
  validates :frequency, presence: true
  validates :next_occurrence, presence: true

  scope :active, -> { where(active: true) }
end
