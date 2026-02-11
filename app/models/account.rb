class Account < ApplicationRecord
  belongs_to :user
  belongs_to :account_group, optional: true
  has_many :transactions, dependent: :destroy
  has_many :balance_snapshots, class_name: "AccountBalanceSnapshot", dependent: :destroy
  has_many :incoming_transfers, class_name: "Transaction", foreign_key: :destination_account_id
  has_many :holdings, dependent: :destroy
  has_many :asset_valuations, dependent: :destroy
  has_many :account_shares, dependent: :destroy

  enum :account_type, { checking: 0, savings: 1, credit_card: 2, cash: 3, investment: 4, property: 5, vehicle: 6 }

  validates :name, presence: true
  validates :account_type, presence: true
  validates :balance, numericality: true
  validates :currency, presence: true, inclusion: { in: ExchangeConversion::SUPPORTED_CURRENCIES.keys, message: "is not a supported currency" }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered, -> { order(:position, :name) }
  scope :included_in_net_worth, -> { where(exclude_from_net_worth: false) }

  after_update :record_balance_snapshot, if: :saved_change_to_balance?

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def goal_progress
    return nil unless balance_goal&.positive?
    (balance / balance_goal * 100).clamp(0, 100).to_f
  end

  def balance_change_this_month
    start_of_month = Date.current.beginning_of_month
    snapshot = balance_snapshots.where("date <= ?", start_of_month).order(date: :desc).first
    return nil unless snapshot
    prior = snapshot.balance
    return nil if prior.zero?
    ((balance - prior) / prior * 100).round(1)
  end

  def asset?
    checking? || savings? || cash? || investment? || property? || vehicle?
  end

  def liability?
    credit_card?
  end

  # Investment portfolio methods
  def portfolio_value
    holdings.sum { |h| h.current_value }
  end

  def total_cost_basis
    holdings.sum { |h| h.total_cost_basis }
  end

  def total_unrealized_gain_loss
    portfolio_value - total_cost_basis
  end

  def total_return_percent
    basis = total_cost_basis
    return 0 if basis.zero?
    ((portfolio_value - basis) / basis * 100).round(2)
  end

  # Property/Vehicle appreciation methods
  def appreciating?
    return false unless property? || vehicle?
    vals = asset_valuations.order(:date).last(2)
    vals.size >= 2 && vals.last.value > vals.first.value
  end

  def appreciation_rate
    return nil unless property? || vehicle?
    vals = asset_valuations.order(:date)
    return nil if vals.size < 2
    first_val = vals.first
    last_val = vals.last
    years = (last_val.date - first_val.date).to_f / 365.25
    return nil if years <= 0 || first_val.value.zero?
    (((last_val.value / first_val.value)**(1.0 / years) - 1) * 100).round(1)
  end

  # Shared account methods
  def shared?
    account_shares.accepted.any?
  end

  def shared_with?(user)
    account_shares.accepted.where(user: user).exists?
  end

  def permission_for(user)
    account_shares.accepted.find_by(user: user)&.permission_level
  end

  def loan_account?
    original_loan_amount.present? && original_loan_amount.positive?
  end

  def loan_progress
    return nil unless loan_account? && balance.positive?
    paid = original_loan_amount - balance
    (paid / original_loan_amount * 100).clamp(0, 100).to_f
  end

  def monthly_payment_estimate
    return nil unless loan_account? && loan_term_months&.positive? && interest_rate&.positive?
    r = interest_rate / 100.0 / 12.0
    n = loan_term_months
    p = original_loan_amount
    (p * r * (1 + r)**n / ((1 + r)**n - 1)).round(2)
  end

  def credit_utilization
    return nil unless credit_card? && credit_limit&.positive?
    (balance / credit_limit * 100).clamp(0, 100).to_f
  end

  def credit_utilization_status
    util = credit_utilization
    return nil unless util
    if util <= 33 then :good
    elsif util <= 66 then :warning
    else :danger
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name account_type description archived_at balance_goal]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account_group]
  end

  private

  def record_balance_snapshot
    AccountBalanceSnapshot.record_for(self)
  end
end
