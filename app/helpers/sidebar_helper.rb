module SidebarHelper
  ICON_COLORS = {
    "home" => "text-blue-500",
    "building-library" => "text-emerald-500",
    "arrows-right-left" => "text-purple-500",
    "calculator" => "text-orange-500",
    "tag" => "text-pink-500",
    "chart-bar" => "text-indigo-500",
    "flag" => "text-red-500",
    "arrow-path" => "text-cyan-500",
    "bell-alert" => "text-amber-500",
    "bell" => "text-yellow-500",
    "shield-check" => "text-slate-500",
    "banknotes" => "text-green-500",
    "credit-card" => "text-violet-500",
    "hashtag" => "text-teal-500",
    "gift" => "text-rose-500",
    "clipboard-document-list" => "text-gray-500",
    "arrow-down-tray" => "text-teal-500",
    "puzzle-piece" => "text-sky-500",
    "light-bulb" => "text-amber-400"
  }.freeze

  def sidebar_link(label, path, icon:, badge: nil)
    active = current_page?(path)
    base = "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 relative group"
    active_class = "glass text-primary-700 dark:text-primary-300 shadow-md"
    inactive_class = "text-text-secondary hover:glass hover:text-text-primary hover:shadow-sm"
    icon_color = ICON_COLORS[icon] || "text-text-muted"

    link_to path, class: "#{base} #{active ? active_class : inactive_class}" do
      if active
        concat(content_tag(:div, "",
          class: "absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-gradient-to-b from-primary-600 to-primary-700 rounded-r-full"))
      end
      concat(heroicon(icon, variant: :outline, options: {
        class: "w-5 h-5 shrink-0 #{active ? icon_color : "text-text-muted group-hover:#{icon_color}"} transition-colors"
      }))
      concat(content_tag(:span, label, data: { sidebar_target: "label" }))
      if badge
        concat(content_tag(:span, badge,
          class: "ml-auto text-xs font-medium px-2 py-0.5 rounded-full glass text-primary-700 dark:text-primary-300 shadow-sm",
          data: { sidebar_target: "label" }))
      end
    end
  end

  def sidebar_section(label)
    content_tag(:div, class: "px-3 pt-5 pb-2 flex items-center gap-2") do
      concat(content_tag(:p, label,
        class: "text-xs font-bold uppercase tracking-wider text-text-muted",
        data: { sidebar_target: "label" }))
      concat(content_tag(:div, "",
        class: "flex-1 h-px bg-gradient-to-r from-border to-transparent"))
    end
  end
end
