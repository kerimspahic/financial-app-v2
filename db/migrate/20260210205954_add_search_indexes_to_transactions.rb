class AddSearchIndexesToTransactions < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"
    add_index :transactions, :description, using: :gin, opclass: :gin_trgm_ops, name: "idx_transactions_description_trgm"
    add_index :transactions, :notes, using: :gin, opclass: :gin_trgm_ops, name: "idx_transactions_notes_trgm"
  end
end
