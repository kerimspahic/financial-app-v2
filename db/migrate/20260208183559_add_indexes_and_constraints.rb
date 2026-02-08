class AddIndexesAndConstraints < ActiveRecord::Migration[8.1]
  def change
    # Composite indexes for common query patterns
    add_index :transactions, [ :user_id, :transaction_type, :date ], name: "idx_transactions_user_type_date"
    add_index :transactions, [ :user_id, :date ], name: "idx_transactions_user_date"
    add_index :budgets, [ :user_id, :month, :year ], name: "idx_budgets_user_month_year"

    # Unique index to enforce budget uniqueness at DB level
    add_index :budgets, [ :user_id, :category_id, :month, :year ], unique: true, name: "idx_budgets_unique_per_category_month"

    # NOT NULL constraints for columns with presence validations
    change_column_null :accounts, :name, false
    change_column_null :accounts, :account_type, false
    change_column_null :categories, :name, false
    change_column_null :categories, :category_type, false
    change_column_null :transactions, :description, false
    change_column_null :transactions, :date, false
    change_column_null :transactions, :transaction_type, false
    change_column_null :budgets, :month, false
    change_column_null :budgets, :year, false
  end
end
