module AdminNavHelper
  ADMIN_NAV_ITEMS = [
    { label: "Dashboard", icon: "chart-bar-square", section: :dashboard, group: :overview },
    { label: "Users", icon: "users", section: :users, group: :access },
    { label: "Roles", icon: "shield-check", section: :roles, group: :access },
    { label: "Settings", icon: "cog-6-tooth", section: :settings, group: :system },
    { label: "Announcements", icon: "megaphone", section: :announcements, group: :system },
    { label: "Audit Log", icon: "clipboard-document-list", section: :audit_logs, group: :monitoring },
    { label: "System Health", icon: "server-stack", section: :system_health, group: :monitoring },
    { label: "Export", icon: "arrow-down-tray", section: :exports, group: :data }
  ].freeze

  ADMIN_NAV_GROUPS = {
    overview: "Overview",
    access: "Users & Access",
    system: "System",
    monitoring: "Monitoring",
    data: "Data"
  }.freeze

  def admin_nav_path(section)
    case section
    when :dashboard then admin_root_path
    when :users then admin_users_path
    when :roles then admin_roles_path
    when :settings then admin_settings_path
    when :announcements then admin_announcements_path
    when :audit_logs then admin_audit_logs_path
    when :system_health then admin_system_health_path
    when :exports then admin_exports_path
    end
  end

  def admin_nav_link(item)
    active = @admin_section == item[:section]
    path = admin_nav_path(item[:section])

    link_to path, class: admin_nav_link_classes(active) do
      safe_join([
        heroicon(item[:icon], variant: :outline, options: { class: "w-5 h-5 shrink-0 #{active ? 'text-primary-500' : 'text-text-muted'}" }),
        content_tag(:span, item[:label])
      ])
    end
  end

  private

  def admin_nav_link_classes(active)
    base = "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200"
    if active
      "#{base} glass text-primary-600 dark:text-primary-400"
    else
      "#{base} text-text-secondary hover:glass hover:text-text-primary"
    end
  end
end
