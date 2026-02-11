class SavingsGoal < ApplicationRecord
  belongs_to :user
  belongs_to :account, optional: true
  has_many :savings_contributions, dependent: :destroy

  validates :name, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :current_amount, numericality: { greater_than_or_equal_to: 0 }

  def progress_percentage
    return 0 unless target_amount.positive?
    (current_amount / target_amount * 100).clamp(0, 100).to_f
  end

  def remaining_amount
    [ target_amount - current_amount, 0 ].max
  end

  def days_remaining
    return nil unless deadline
    (deadline - Date.current).to_i
  end

  def on_track?
    return true unless deadline
    return true if progress_percentage >= 100
    days_total = (deadline - created_at.to_date).to_i
    days_elapsed = (Date.current - created_at.to_date).to_i
    return true if days_total.zero?
    expected_progress = (days_elapsed.to_f / days_total * 100)
    progress_percentage >= expected_progress
  end
end
