class AddClearingStatusToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :clearing_status, :integer, default: 0, null: false
    add_index :transactions, [ :account_id, :clearing_status ]

    reversible do |dir|
      dir.up do
        execute "UPDATE transactions SET clearing_status = 2 WHERE reconciled = true"
      end
    end
  end
end
