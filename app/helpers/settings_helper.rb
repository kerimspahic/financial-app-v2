module SettingsHelper
  def color_swatch_class(color)
    "color-preview-#{color}"
  end

  def theme_mode_icon(mode)
    case mode
    when "light" then "sun"
    when "dark" then "moon"
    when "system" then "computer-desktop"
    end
  end
end
