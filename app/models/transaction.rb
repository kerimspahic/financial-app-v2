class Transaction < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  belongs_to :account
  belongs_to :category
  belongs_to :destination_account, class_name: "Account", optional: true
  belongs_to :transaction_group, optional: true
  belongs_to :contra_category, class_name: "Category", optional: true
  has_many :transaction_tags, dependent: :destroy
  has_many :tags, through: :transaction_tags
  has_many_attached :receipts

  enum :transaction_type, { income: 0, expense: 1, transfer: 2 }
  enum :clearing_status, { uncleared: 0, cleared: 1, reconciled: 2 }
  enum :flag, { red: 0, orange: 1, yellow: 2, green: 3, blue: 4, purple: 5 }, prefix: :flag

  scope :uncleared_only, -> { where(clearing_status: :uncleared) }
  scope :cleared_only, -> { where(clearing_status: :cleared) }
  scope :reconciled_only, -> { where(clearing_status: :reconciled) }
  scope :needs_review, -> { where(needs_review: true) }
  scope :reviewed, -> { where(needs_review: false) }
  scope :flagged, -> { where.not(flag: nil) }
  scope :unflagged, -> { where(flag: nil) }
  scope :included_in_reports, -> { where(exclude_from_reports: false) }
  scope :excluded_from_reports, -> { where(exclude_from_reports: true) }

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
  validate :receipt_validations

  ALLOWED_RECEIPT_TYPES = %w[image/jpeg image/png image/webp application/pdf].freeze
  MAX_RECEIPT_SIZE = 10.megabytes
  MAX_RECEIPTS = 5

  def split?
    transaction_splits.any?
  end

  def converted?
    original_amount.present?
  end

  # Full-text search via pg_search
  pg_search_scope :search_all,
    against: [ :description, :notes, :payee ],
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
    %w[description amount transaction_type date created_at notes account_id category_id reconciled destination_account_id clearing_status payee flag needs_review exclude_from_reports currency]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[account category tags]
  end

  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :by_month, ->(month, year) { where(date: Date.new(year, month)..Date.new(year, month).end_of_month) }

  # Flag display helpers
  FLAG_COLORS = {
    "red" => { bg: "bg-red-100 dark:bg-red-500/20", text: "text-red-600 dark:text-red-400", dot: "#ef4444" },
    "orange" => { bg: "bg-orange-100 dark:bg-orange-500/20", text: "text-orange-600 dark:text-orange-400", dot: "#f97316" },
    "yellow" => { bg: "bg-yellow-100 dark:bg-yellow-500/20", text: "text-yellow-600 dark:text-yellow-400", dot: "#eab308" },
    "green" => { bg: "bg-green-100 dark:bg-green-500/20", text: "text-green-600 dark:text-green-400", dot: "#22c55e" },
    "blue" => { bg: "bg-blue-100 dark:bg-blue-500/20", text: "text-blue-600 dark:text-blue-400", dot: "#3b82f6" },
    "purple" => { bg: "bg-purple-100 dark:bg-purple-500/20", text: "text-purple-600 dark:text-purple-400", dot: "#a855f7" }
  }.freeze

  def flag_color
    FLAG_COLORS[flag] || {}
  end

  # Distinct payees for a user (for payee management)
  def self.distinct_payees(user)
    where(user: user)
      .where.not(payee: [ nil, "" ])
      .group(:payee)
      .select("payee, COUNT(*) as transaction_count, SUM(amount) as total_amount")
      .order("transaction_count DESC")
  end

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

  def receipt_validations
    if receipts.attached? && receipts.count > MAX_RECEIPTS
      errors.add(:receipts, "cannot exceed #{MAX_RECEIPTS} files")
    end

    receipts.each do |receipt|
      unless ALLOWED_RECEIPT_TYPES.include?(receipt.content_type)
        errors.add(:receipts, "must be JPEG, PNG, WebP, or PDF")
      end
      if receipt.byte_size > MAX_RECEIPT_SIZE
        errors.add(:receipts, "must be smaller than 10MB each")
      end
    end
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
