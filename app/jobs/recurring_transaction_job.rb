class RecurringTransactionJob < ApplicationJob
  include BalanceUpdatable

  queue_as :default

  def perform
    RecurringTransaction.active.where("next_occurrence <= ?", Date.current).find_each do |recurring|
      generate_transaction(recurring)
    end
  end

  private

  def generate_transaction(recurring)
    transaction = recurring.user.transactions.build(
      description: recurring.description,
      amount: recurring.amount,
      transaction_type: recurring.transaction_type,
      date: recurring.next_occurrence,
      account: recurring.account,
      category: recurring.category,
      clearing_status: :uncleared,
      notes: "Auto-generated from recurring: #{recurring.description}"
    )

    ActiveRecord::Base.transaction do
      if transaction.save
        update_account_balance(transaction)
        recurring.update!(
          next_occurrence: advance_date(recurring.next_occurrence, recurring.frequency),
          last_generated_at: Time.current
        )
        Rails.logger.info "[RecurringTransactionJob] Generated transaction ##{transaction.id} for '#{recurring.description}'"
        PushNotificationService.recurring_generated(recurring.user, transaction, recurring)
      else
        Rails.logger.warn "[RecurringTransactionJob] Failed to generate for '#{recurring.description}': #{transaction.errors.full_messages.join(', ')}"
      end
    end
  rescue => e
    Rails.logger.error "[RecurringTransactionJob] Error for recurring ##{recurring.id}: #{e.message}"
  end

  def advance_date(date, frequency)
    case frequency
    when "daily" then date + 1.day
    when "weekly" then date + 1.week
    when "biweekly" then date + 2.weeks
    when "monthly" then date + 1.month
    when "quarterly" then date + 3.months
    when "yearly" then date + 1.year
    else date + 1.month
    end
  end
end
