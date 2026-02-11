class Holding < ApplicationRecord
  belongs_to :account

  validates :symbol, presence: true, uniqueness: { scope: :account_id, message: "already exists in this account" }
  validates :shares, presence: true, numericality: { greater_than: 0 }
  validates :cost_basis_per_share, presence: true, numericality: { greater_than: 0 }

  scope :ordered, -> { order(:symbol) }

  def total_cost_basis
    shares * cost_basis_per_share
  end

  def current_value
    return nil unless current_price
    shares * current_price
  end

  def display_value
    current_value || total_cost_basis
  end

  def unrealized_gain_loss
    return nil unless current_value
    current_value - total_cost_basis
  end

  def unrealized_gain_loss_percent
    return nil unless current_value
    return 0 if total_cost_basis.zero?
    ((current_value - total_cost_basis) / total_cost_basis * 100).round(2)
  end

  def gain_or_loss?
    return nil unless unrealized_gain_loss
    unrealized_gain_loss >= 0 ? :gain : :loss
  end

  def allocation_percentage(total_portfolio_value)
    return 0 unless display_value && total_portfolio_value.positive?
    (display_value / total_portfolio_value * 100).round(1)
  end
end
