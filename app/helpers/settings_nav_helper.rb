module SettingsNavHelper
  SETTINGS_NAV_ITEMS = [
    { label: "Profile", icon: "user-circle", section: :profile, group: :account },
    { label: "Security", icon: "lock-closed", section: :security, group: :account },
    { label: "Appearance", icon: "swatch", section: :appearance, group: :preferences },
    { label: "Preferences", icon: "adjustments-horizontal", section: :preferences, group: :preferences },
    { label: "Categories", icon: "tag", section: :categories, group: :data },
    { label: "Notifications", icon: "bell", section: :notifications, group: :data }
  ].freeze

  SETTINGS_NAV_GROUPS = {
    account: "Account",
    preferences: "Customization",
    data: "Data & Alerts"
  }.freeze

  def settings_nav_path(section)
    case section
    when :profile then settings_profile_path
    when :security then settings_security_path
    when :appearance then settings_appearance_path
    when :preferences then settings_preferences_path
    when :categories then settings_categories_path
    when :notifications then settings_notifications_path
    end
  end

  def settings_nav_link(item)
    active = @settings_section == item[:section]
    path = settings_nav_path(item[:section])

    link_to path, class: settings_nav_link_classes(active) do
      safe_join([
        heroicon(item[:icon], variant: :outline, options: { class: "w-5 h-5 shrink-0 #{active ? 'text-primary-500' : 'text-text-muted'}" }),
        content_tag(:span, item[:label])
      ])
    end
  end

  private

  def settings_nav_link_classes(active)
    base = "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200"
    if active
      "#{base} glass text-primary-600 dark:text-primary-400"
    else
      "#{base} text-text-secondary hover:glass hover:text-text-primary"
    end
  end
end
