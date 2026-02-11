class TransactionSplit < ApplicationRecord
  belongs_to :parent_transaction, class_name: "Transaction", foreign_key: :transaction_id
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :category_belongs_to_user

  private

  def category_belongs_to_user
    return unless parent_transaction&.user_id && category_id
    errors.add(:category, "is not valid") unless Category.exists?(id: category_id, user_id: parent_transaction.user_id)
  end
end
