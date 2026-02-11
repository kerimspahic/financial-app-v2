class CreateAssetValuations < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_valuations do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :value, precision: 12, scale: 2, null: false
      t.date :date, null: false
      t.string :source
      t.text :notes
      t.timestamps
    end

    add_index :asset_valuations, [ :account_id, :date ], unique: true
  end
end
