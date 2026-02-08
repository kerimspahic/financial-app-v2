class SavingsGoal < ApplicationRecord
  belongs_to :user
  has_many :savings_contributions, dependent: :destroy

  validates :name, presence: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :current_amount, numericality: { greater_than_or_equal_to: 0 }
end
