class CreateTransactionGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_groups do |t|
      t.string :name, null: false
      t.integer :group_type, null: false, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :transaction_groups, [ :user_id, :name ], unique: true
  end
end
