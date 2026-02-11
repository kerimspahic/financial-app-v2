class BillPayment < ApplicationRecord
  belongs_to :bill
  belongs_to :linked_transaction, class_name: "Transaction", foreign_key: :transaction_id, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_date, presence: true
end
