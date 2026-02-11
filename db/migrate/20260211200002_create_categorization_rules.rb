class CreateCategorizationRules < ActiveRecord::Migration[8.1]
  def change
    create_table :categorization_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :pattern, null: false
      t.integer :match_type, null: false, default: 0
      t.integer :priority, default: 0
      t.timestamps
    end

    add_index :categorization_rules, [ :user_id, :priority ]
  end
end
