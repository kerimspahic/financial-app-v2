class StatCardComponent < ApplicationComponent
  def initialize(label:, value:, icon: nil, color: nil, change: nil, **options)
    @label = label
    @value = value
    @icon = icon
    @color = color
    @change = change
    @options = options
  end

  def value_color
    @color || "text-text-primary"
  end

  def change_color
    return "" unless @change
    @change.to_f >= 0 ? "text-success-600" : "text-danger-600"
  end

  def change_icon
    return nil unless @change
    @change.to_f >= 0 ? "arrow-trending-up" : "arrow-trending-down"
  end
end
