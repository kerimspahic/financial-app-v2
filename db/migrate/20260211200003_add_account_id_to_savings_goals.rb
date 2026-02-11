class AddAccountIdToSavingsGoals < ActiveRecord::Migration[8.1]
  def change
    add_reference :savings_goals, :account, foreign_key: true, null: true
  end
end
