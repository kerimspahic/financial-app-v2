class Transaction < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  belongs_to :account
  belongs_to :category
  belongs_to :destination_account, class_name: "Account", optional: true
  has_many :transaction_tags, dependent: :destroy
  has_many :tags, through: :transaction_tags

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }
  enum :clearing_status, { uncleared: 0, cleared: 1, reconciled: 2 }

  scope :uncleared_only, -> { where(clearing_status: :uncleared) }
  scope :cleared_only, -> { where(clearing_status: :cleared) }
  scope :reconciled_only, -> { where(clearing_status: :reconciled) }

  has_many :transaction_splits, dependent: :destroy
  accepts_nested_attributes_for :transaction_splits, allow_destroy: true, reject_if: :all_blank

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true
  validates :date, presence: true
  validate :account_belongs_to_user
  validate :category_belongs_to_user
  validate :destination_account_valid
  validate :cannot_modify_reconciled, on: :update
  validate :splits_sum_matches_amount

  def split?
    transaction_splits.any?
  end

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
    %w[description amount transaction_type date created_at notes account_id category_id reconciled destination_account_id clearing_status]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account category tags]
  end

  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :by_month, ->(month, year) { where(date: Date.new(year, month)..Date.new(year, month).end_of_month) }

  private

  def cannot_modify_reconciled
    return unless clearing_status_was == "reconciled"
    changed_attrs = changes.keys - [ "clearing_status", "updated_at" ]
    if changed_attrs.any?
      errors.add(:base, "Reconciled transactions cannot be modified. Change status to Cleared first.")
    end
  end

  def splits_sum_matches_amount
    return unless split?
    splits_total = transaction_splits.reject(&:marked_for_destruction?).sum(&:amount)
    if (splits_total - amount).abs > 0.01
      errors.add(:base, "Split amounts must equal the transaction amount")
    end
  end

  def account_belongs_to_user
    return unless user_id && account_id
    errors.add(:account, "is not valid") unless Account.exists?(id: account_id, user_id: user_id)
  end

  def category_belongs_to_user
    return unless user_id && category_id
    errors.add(:category, "is not valid") unless Category.exists?(id: category_id, user_id: user_id)
  end

  def destination_account_valid
    if transfer?
      if destination_account_id.blank?
        errors.add(:destination_account, "is required for transfers")
      elsif destination_account_id == account_id
        errors.add(:destination_account, "must be different from source account")
      elsif user_id && !Account.exists?(id: destination_account_id, user_id: user_id)
        errors.add(:destination_account, "is not valid")
      end
    end
  end
end
