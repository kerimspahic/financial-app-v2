class CreateAccountGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :account_groups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :account_groups, [ :user_id, :name ], unique: true
  end
end
