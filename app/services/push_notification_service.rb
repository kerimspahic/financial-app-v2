class PushNotificationService
  # Create in-app notification records for various events.
  #
  # Usage:
  #   PushNotificationService.notify(user, :recurring_generated, "Recurring Transaction Generated",
  #     "Monthly rent payment of $1,200 was automatically created.",
  #     metadata: { transaction_id: 123 })
  #
  def self.notify(user, event_type, title, message, metadata: {})
    new(user, event_type, title, message, metadata: metadata).deliver
  end

  def initialize(user, event_type, title, message, metadata: {})
    @user = user
    @event_type = event_type.to_s
    @title = title
    @message = message
    @metadata = metadata
  end

  def deliver
    return unless should_notify?

    notification = @user.notifications.create!(
      notification_type: @event_type,
      title: @title,
      body: @message,
      actionable_url: build_actionable_url,
      read: false
    )

    Rails.logger.info "[PushNotification] Created notification ##{notification.id} (#{@event_type}) for user ##{@user.id}"
    notification
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "[PushNotification] Failed to create notification: #{e.message}"
    nil
  end

  # Convenience methods for specific event types

  def self.recurring_generated(user, transaction, recurring_transaction)
    notify(
      user,
      :recurring_generated,
      "Recurring Transaction Generated",
      "\"#{transaction.description}\" for #{ActionController::Base.helpers.number_to_currency(transaction.amount)} was automatically created from your recurring schedule.",
      metadata: {
        transaction_id: transaction.id,
        recurring_transaction_id: recurring_transaction.id
      }
    )
  end

  def self.import_complete(user, result, filename)
    imported = result[:imported] || 0
    duplicates = result[:duplicates] || 0
    errors = result[:errors]&.size || 0

    parts = [ "#{imported} imported" ]
    parts << "#{duplicates} duplicates skipped" if duplicates > 0
    parts << "#{errors} errors" if errors > 0

    notify(
      user,
      :import_complete,
      "Import Complete",
      "#{filename}: #{parts.join(', ')}.",
      metadata: { filename: filename, imported: imported, duplicates: duplicates, errors: errors }
    )
  end

  def self.budget_exceeded(user, budget)
    notify(
      user,
      :budget_exceeded,
      "Budget Exceeded",
      "Your #{budget.category.name} budget for this month has been exceeded. Spent #{ActionController::Base.helpers.number_to_currency(budget.spent)} of #{ActionController::Base.helpers.number_to_currency(budget.amount)}.",
      metadata: { budget_id: budget.id, category_id: budget.category_id }
    )
  end

  private

  def should_notify?
    # Check user notification preferences if they exist
    pref = @user.notification_preferences.find_by(notification_type: @event_type)
    return true unless pref
    pref.in_app?
  end

  def build_actionable_url
    case @event_type
    when "recurring_generated"
      "/transactions"
    when "import_complete"
      "/transactions"
    when "budget_exceeded"
      "/budgets"
    else
      nil
    end
  end
end
