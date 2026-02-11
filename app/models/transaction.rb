class Transaction < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  belongs_to :account
  belongs_to :category
  has_many :transaction_tags, dependent: :destroy
  has_many :tags, through: :transaction_tags

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true
  validates :date, presence: true
  validate :account_belongs_to_user
  validate :category_belongs_to_user

  # Full-text search via pg_search
  pg_search_scope :search_all,
    against: [ :description, :notes ],
    associated_against: {
      category: [ :name ],
      account: [ :name ]
    },
    using: {
      tsearch: { prefix: true },
      trigram: { threshold: 0.3 }
    }

  # Ransack allowlists
  def self.ransackable_attributes(auth_object = nil)
    %w[description amount transaction_type date created_at notes account_id category_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account category tags]
  end

  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :by_month, ->(month, year) { where(date: Date.new(year, month)..Date.new(year, month).end_of_month) }

  private

  def account_belongs_to_user
    return unless user_id && account_id
    errors.add(:account, "is not valid") unless Account.exists?(id: account_id, user_id: user_id)
  end

  def category_belongs_to_user
    return unless user_id && category_id
    errors.add(:category, "is not valid") unless Category.exists?(id: category_id, user_id: user_id)
  end
end
