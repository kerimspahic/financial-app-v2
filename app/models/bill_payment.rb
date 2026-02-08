class BillPayment < ApplicationRecord
  belongs_to :bill
  belongs_to :transaction, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_date, presence: true
end
