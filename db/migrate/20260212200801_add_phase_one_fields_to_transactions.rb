class AddPhaseOneFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :payee, :string
    add_column :transactions, :flag, :integer
    add_column :transactions, :needs_review, :boolean, default: false, null: false
    add_column :transactions, :exclude_from_reports, :boolean, default: false, null: false

    add_index :transactions, :payee, using: :gin, opclass: :gin_trgm_ops, name: "idx_transactions_payee_trgm"
    add_index :transactions, :flag, where: "flag IS NOT NULL", name: "idx_transactions_flag"
    add_index :transactions, :needs_review, where: "needs_review = true", name: "idx_transactions_needs_review"
  end
end
