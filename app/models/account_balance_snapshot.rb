class AccountBalanceSnapshot < ApplicationRecord
  belongs_to :account

  validates :balance, presence: true
  validates :date, presence: true, uniqueness: { scope: :account_id }

  scope :recent, -> { order(date: :desc) }
  scope :for_period, ->(start_date, end_date) { where(date: start_date..end_date) }

  def self.record_for(account)
    find_or_initialize_by(account: account, date: Date.current).tap do |snapshot|
      snapshot.update!(balance: account.balance)
    end
  end
end
