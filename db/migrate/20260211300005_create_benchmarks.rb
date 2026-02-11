class CreateBenchmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :benchmarks do |t|
      t.string :name, null: false
      t.jsonb :monthly_returns, default: {}
      t.timestamps
    end
  end
end
