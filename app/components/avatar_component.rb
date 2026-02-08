class AvatarComponent < ApplicationComponent
  SIZES = {
    sm: "w-8 h-8 text-xs",
    md: "w-10 h-10 text-sm",
    lg: "w-12 h-12 text-base"
  }.freeze

  COLORS = %w[
    bg-primary-500 bg-success-500 bg-warning-500 bg-danger-500 bg-info-500
  ].freeze

  def initialize(name:, size: :md, **options)
    @name = name
    @size = size.to_sym
    @options = options
  end

  def initials
    parts = @name.to_s.strip.split(/[\s@.]+/)
    if parts.length >= 2
      "#{parts[0][0]}#{parts[1][0]}".upcase
    else
      @name.to_s[0..1].upcase
    end
  end

  def size_class
    SIZES[@size] || SIZES[:md]
  end

  def color_class
    COLORS[@name.to_s.bytes.sum % COLORS.length]
  end
end
