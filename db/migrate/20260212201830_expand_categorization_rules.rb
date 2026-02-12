class ExpandCategorizationRules < ActiveRecord::Migration[8.1]
  def change
    add_column :categorization_rules, :match_field, :integer, default: 0, null: false
    add_column :categorization_rules, :actions, :jsonb, default: []
    add_column :categorization_rules, :active, :boolean, default: true, null: false

    # Make category_id optional since rules can now have actions instead of just category assignment
    change_column_null :categorization_rules, :category_id, true
  end
end
