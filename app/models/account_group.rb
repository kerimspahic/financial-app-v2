class AccountGroup < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :ordered, -> { order(:position, :name) }

  def total_balance
    accounts.where(archived_at: nil).sum(:balance)
  end
end
