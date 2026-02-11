class AddTransferFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :destination_account, null: true, foreign_key: { to_table: :accounts }
    add_column :transactions, :reconciled, :boolean, default: false
  end
end
