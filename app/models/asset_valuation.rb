class AssetValuation < ApplicationRecord
  belongs_to :account

  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true, uniqueness: { scope: :account_id }

  scope :recent, -> { order(date: :desc) }
  scope :for_period, ->(start_date, end_date) { where(date: start_date..end_date) }

  after_save :update_account_balance

  private

  def update_account_balance
    latest = account.asset_valuations.recent.first
    account.update_columns(balance: latest.value) if latest == self
  end
end
