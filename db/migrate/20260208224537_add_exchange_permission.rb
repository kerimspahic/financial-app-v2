class AddExchangePermission < ActiveRecord::Migration[8.1]
  def up
    Permission.find_or_create_by!(key: "manage_exchanges") do |p|
      p.description = "Convert currencies and view exchange history"
    end
  end

  def down
    Permission.find_by(key: "manage_exchanges")&.destroy
  end
end
