class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name
      t.integer :category_type
      t.string :color
      t.string :icon
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
