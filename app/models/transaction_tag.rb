class TransactionTag < ApplicationRecord
  belongs_to :transaction
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :transaction_id }
end
