class NotificationPreference < ApplicationRecord
  belongs_to :user

  enum :notification_type, {
    budget_warning: 0, budget_exceeded: 1,
    bill_reminder: 2, bill_overdue: 3,
    goal_milestone: 4, monthly_summary: 5, weekly_digest: 6
  }

  validates :notification_type, presence: true, uniqueness: { scope: :user_id }
end
