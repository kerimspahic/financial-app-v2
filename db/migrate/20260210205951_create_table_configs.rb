class CreateTableConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :table_configs do |t|
      t.string :page_key, null: false
      t.jsonb :columns, default: []
      t.jsonb :search_fields, default: []
      t.jsonb :filters, default: []

      t.timestamps
    end

    add_index :table_configs, :page_key, unique: true
  end
end
