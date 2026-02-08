class SavingsContribution < ApplicationRecord
  belongs_to :savings_goal

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :date, presence: true
end
