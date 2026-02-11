class Account < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  enum :account_type, { checking: 0, savings: 1, credit_card: 2, cash: 3, investment: 4 }

  validates :name, presence: true
  validates :account_type, presence: true
  validates :balance, numericality: true

  def self.ransackable_attributes(auth_object = nil)
    %w[name account_type]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
