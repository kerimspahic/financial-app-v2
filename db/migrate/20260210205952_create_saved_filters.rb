class CreateSavedFilters < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_filters do |t|
      t.references :user, null: false, foreign_key: true
      t.string :page_key, null: false
      t.string :name, null: false
      t.jsonb :filter_params, default: {}
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :saved_filters, [ :user_id, :page_key ]
    add_index :saved_filters, [ :user_id, :page_key, :name ], unique: true
  end
end
