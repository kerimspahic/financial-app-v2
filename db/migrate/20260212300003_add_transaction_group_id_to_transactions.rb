class AddTransactionGroupIdToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :transaction_group, null: true, foreign_key: true
  end
end
