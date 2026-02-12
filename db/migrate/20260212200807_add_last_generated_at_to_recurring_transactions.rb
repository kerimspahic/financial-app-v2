class AddLastGeneratedAtToRecurringTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :recurring_transactions, :last_generated_at, :datetime
  end
end
