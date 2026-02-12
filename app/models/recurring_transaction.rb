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
  scope :due, -> { active.where("next_occurrence <= ?", Date.current) }

  def self.ransackable_attributes(auth_object = nil)
    %w[description amount transaction_type frequency next_occurrence active account_id category_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account category]
  end

  def overdue?
    active? && next_occurrence < Date.current
  end

  def days_until_next
    (next_occurrence - Date.current).to_i
  end
end
