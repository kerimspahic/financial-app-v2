class CreateCustomFieldDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_field_definitions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :field_type, null: false
      t.jsonb :options, default: {}
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
