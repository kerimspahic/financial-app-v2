module BalanceUpdatable
  extend ActiveSupport::Concern

  private

  def save_transaction_with_balance(transaction)
    ActiveRecord::Base.transaction do
      if transaction.save
        update_account_balance(transaction)
        true
      else
        false
      end
    end
  end

  def update_transaction_with_balance(transaction, old_transaction, params)
    ActiveRecord::Base.transaction do
      if transaction.update(params)
        reverse_account_balance(old_transaction)
        update_account_balance(transaction)
        true
      else
        false
      end
    end
  end

  def destroy_transaction_with_balance(transaction)
    ActiveRecord::Base.transaction do
      reverse_account_balance(transaction)
      transaction.destroy
    end
  end

  def update_account_balance(transaction)
    account = transaction.account
    if transaction.income?
      account.increment!(:balance, transaction.amount)
    elsif transaction.expense?
      account.decrement!(:balance, transaction.amount)
    elsif transaction.transfer?
      account.decrement!(:balance, transaction.amount)
      transaction.destination_account&.increment!(:balance, transaction.amount)
    end
  end

  def reverse_account_balance(transaction)
    account = transaction.account
    if transaction.income?
      account.decrement!(:balance, transaction.amount)
    elsif transaction.expense?
      account.increment!(:balance, transaction.amount)
    elsif transaction.transfer?
      account.increment!(:balance, transaction.amount)
      transaction.destination_account&.decrement!(:balance, transaction.amount)
    end
  end
end
