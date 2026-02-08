class ProgressBarComponent < ApplicationComponent
  def initialize(value:, max: 100, label: nil, show_percentage: true,
                 warning_threshold: 70, danger_threshold: 90, color: nil, **options)
    @value = value.to_f
    @max = max.to_f
    @label = label
    @show_percentage = show_percentage
    @warning_threshold = warning_threshold
    @danger_threshold = danger_threshold
    @color = color
    @options = options
  end

  def percentage
    return 0 if @max.zero?
    [ (@value / @max * 100).round(1), 100 ].min
  end

  def bar_color
    return @color if @color

    if percentage > @danger_threshold
      "bg-danger-500"
    elsif percentage > @warning_threshold
      "bg-warning-500"
    else
      "bg-success-500"
    end
  end
end
