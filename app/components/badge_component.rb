class BadgeComponent < ApplicationComponent
  VARIANTS = {
    success: "bg-success-50 text-success-700",
    warning: "bg-warning-50 text-warning-700",
    danger: "bg-danger-50 text-danger-700",
    info: "bg-info-50 text-info-700",
    neutral: "bg-surface-hover text-text-secondary"
  }.freeze

  DOT_COLORS = {
    success: "bg-success-500",
    warning: "bg-warning-500",
    danger: "bg-danger-500",
    info: "bg-info-500",
    neutral: "bg-text-muted"
  }.freeze

  SIZES = {
    sm: "px-2 py-0.5 text-xs",
    md: "px-2.5 py-1 text-xs"
  }.freeze

  def initialize(variant: :neutral, dot: false, size: :md, **options)
    @variant = variant.to_sym
    @dot = dot
    @size = size.to_sym
    @options = options
  end

  def css_classes
    [
      "inline-flex items-center gap-1.5 font-medium rounded-full",
      VARIANTS[@variant],
      SIZES[@size],
      @options[:class]
    ].compact.join(" ")
  end

  def dot_class
    DOT_COLORS[@variant]
  end

  def show_dot?
    @dot
  end
end
