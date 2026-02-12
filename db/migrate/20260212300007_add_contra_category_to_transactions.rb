class AddContraCategoryToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :contra_category_id, :bigint
    add_foreign_key :transactions, :categories, column: :contra_category_id
    add_index :transactions, :contra_category_id
  end
end
