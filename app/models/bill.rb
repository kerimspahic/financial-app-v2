class Bill < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :bill_payments, dependent: :destroy

  enum :frequency, { weekly: 0, biweekly: 1, monthly: 2, quarterly: 3, yearly: 4 }

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :frequency, presence: true

  scope :active, -> { where(active: true) }
end
