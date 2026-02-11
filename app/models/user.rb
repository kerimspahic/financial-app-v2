class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_one :user_preference, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :recurring_transactions, dependent: :destroy
  has_many :savings_goals, dependent: :destroy
  has_many :bills, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy
  has_many :debt_accounts, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :exchange_conversions, dependent: :destroy
  has_many :saved_filters, dependent: :destroy

  before_create :set_jti
  after_create :create_default_categories
  after_create :create_default_preferences

  def preference
    user_preference || build_user_preference
  end

  def admin?
    roles.exists?(name: "admin")
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def has_permission?(permission_key)
    return true if admin?

    permissions.exists?(key: permission_key)
  end

  def permissions
    Permission.joins(role_permissions: { role: :user_roles })
              .where(user_roles: { user_id: id })
              .distinct
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end

  def jwt_payload
    super
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end

  def create_default_preferences
    create_user_preference!
  end

  def create_default_categories
    default_categories = [
      { name: "Salary", category_type: :income, color: "#22c55e" },
      { name: "Freelance", category_type: :income, color: "#10b981" },
      { name: "Investments", category_type: :income, color: "#06b6d4" },
      { name: "Other Income", category_type: :income, color: "#8b5cf6" },
      { name: "Housing", category_type: :expense, color: "#ef4444" },
      { name: "Food & Groceries", category_type: :expense, color: "#f97316" },
      { name: "Transportation", category_type: :expense, color: "#eab308" },
      { name: "Utilities", category_type: :expense, color: "#64748b" },
      { name: "Entertainment", category_type: :expense, color: "#ec4899" },
      { name: "Healthcare", category_type: :expense, color: "#14b8a6" },
      { name: "Shopping", category_type: :expense, color: "#a855f7" },
      { name: "Dining Out", category_type: :expense, color: "#f43f5e" },
      { name: "Subscriptions", category_type: :expense, color: "#6366f1" },
      { name: "Education", category_type: :expense, color: "#0ea5e9" }
    ]

    default_categories.each do |cat|
      categories.create!(cat)
    end
  end
end
