class Notification < ApplicationRecord
  belongs_to :user

  enum :notification_type, {
    budget_warning: 0, budget_exceeded: 1,
    bill_reminder: 2, bill_overdue: 3,
    goal_milestone: 4, monthly_summary: 5, weekly_digest: 6,
    recurring_generated: 7, import_complete: 8
  }

  validates :title, presence: true
  validates :notification_type, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
end
