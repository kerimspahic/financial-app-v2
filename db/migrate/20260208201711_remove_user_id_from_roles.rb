class RemoveUserIdFromRoles < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :roles, :users
    remove_reference :roles, :user, index: true
    add_index :roles, :name, unique: true
  end
end
