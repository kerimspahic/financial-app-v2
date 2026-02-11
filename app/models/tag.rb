class Tag < ApplicationRecord
  belongs_to :user
  has_many :transaction_tags, dependent: :destroy
  has_many :transactions, through: :transaction_tags, source: :financial_transaction

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
