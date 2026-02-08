class Category < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify
  has_many :budgets, dependent: :destroy

  enum :category_type, { income: 0, expense: 1 }

  validates :name, presence: true
  validates :category_type, presence: true
end
