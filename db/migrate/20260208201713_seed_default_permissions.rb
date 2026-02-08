class SeedDefaultPermissions < ActiveRecord::Migration[8.1]
  PERMISSIONS = [
    { key: "manage_accounts", description: "Create, edit, and delete accounts" },
    { key: "manage_transactions", description: "Create, edit, and delete transactions" },
    { key: "manage_categories", description: "Create, edit, and delete categories" },
    { key: "manage_budgets", description: "Create, edit, and delete budgets" },
    { key: "manage_settings", description: "View and update personal settings" },
    { key: "view_reports", description: "Access financial reports" },
    { key: "manage_recurring_transactions", description: "Manage recurring transactions" },
    { key: "manage_savings_goals", description: "Manage savings goals" },
    { key: "manage_bills", description: "Manage bills and payments" },
    { key: "view_notifications", description: "View notifications" },
    { key: "manage_debt_accounts", description: "Manage debt tracking" },
    { key: "manage_subscriptions", description: "Manage subscriptions" },
    { key: "manage_tags", description: "Manage tags" },
    { key: "manage_wishlist", description: "Manage wishlist items" },
    { key: "view_audit_logs", description: "View activity logs" },
    { key: "manage_imports", description: "Import and export data" },
    { key: "manage_integrations", description: "Manage integrations" },
    { key: "view_insights", description: "View financial insights" }
  ].freeze

  def up
    PERMISSIONS.each do |perm|
      Permission.find_or_create_by!(key: perm[:key]) do |p|
        p.description = perm[:description]
      end
    end
  end

  def down
    Permission.where(key: PERMISSIONS.map { |p| p[:key] }).destroy_all
  end
end
