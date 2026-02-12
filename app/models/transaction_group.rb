class TransactionGroup < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify

  enum :group_type, { refund: 0, reimbursement: 1, related: 2, installment: 3 }

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :group_type, presence: true

  GROUP_TYPE_COLORS = {
    "refund" => { bg: "bg-success-50 dark:bg-success-500/10", text: "text-success-600 dark:text-success-400", icon: "arrow-uturn-left" },
    "reimbursement" => { bg: "bg-info-50 dark:bg-info-500/10", text: "text-info-600 dark:text-info-400", icon: "banknotes" },
    "related" => { bg: "bg-purple-50 dark:bg-purple-500/10", text: "text-purple-600 dark:text-purple-400", icon: "link" },
    "installment" => { bg: "bg-warning-50 dark:bg-warning-500/10", text: "text-warning-600 dark:text-warning-400", icon: "calendar-days" }
  }.freeze

  def type_display
    GROUP_TYPE_COLORS[group_type] || {}
  end

  def total_amount
    transactions.sum(:amount)
  end
end
