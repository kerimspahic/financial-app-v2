class BillReminderJob < ApplicationJob
  queue_as :default

  def perform
    Bill.active.find_each do |bill|
      next unless bill.reminder_days_before.present? && bill.reminder_days_before > 0
      next if bill.paid_this_period?

      days_until = bill.days_until_due
      next unless days_until >= 0 && days_until <= bill.reminder_days_before

      # Avoid duplicate reminders for the same bill on the same day
      existing = Notification.where(
        user_id: bill.user_id,
        notification_type: :bill_reminder,
        actionable_url: "/bills/#{bill.id}"
      ).where("created_at >= ?", Date.current.beginning_of_day)

      next if existing.exists?

      title = if days_until == 0
        "#{bill.name} is due today"
      else
        "#{bill.name} is due in #{days_until} #{'day'.pluralize(days_until)}"
      end

      Notification.create!(
        user: bill.user,
        notification_type: :bill_reminder,
        title: title,
        body: "#{bill.name} payment of #{ActiveSupport::NumberHelper.number_to_currency(bill.amount)} is due on #{bill.next_due_date.strftime('%b %d, %Y')}.",
        actionable_url: "/bills/#{bill.id}"
      )
    end
  end
end
