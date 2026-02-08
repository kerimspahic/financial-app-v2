class DebtAccount < ApplicationRecord
  belongs_to :user

  enum :strategy, { snowball: 0, avalanche: 1, custom: 2 }

  validates :name, presence: true
  validates :balance, presence: true, numericality: true
end
