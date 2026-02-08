class ButtonComponent < ApplicationComponent
  VARIANTS = {
    primary: "gradient-primary text-white hover:shadow-lg hover:scale-[1.02] focus:ring-primary-500 shadow-md",
    secondary: "glass text-text-primary hover:shadow-md hover:scale-[1.01] focus:ring-primary-500",
    danger: "gradient-danger text-white hover:shadow-lg hover:scale-[1.02] focus:ring-danger-500 shadow-md",
    ghost: "text-text-secondary hover:bg-surface-hover/50 hover:backdrop-blur-sm focus:ring-primary-500"
  }.freeze

  SIZES = {
    sm: "px-3 py-1.5 text-sm",
    md: "px-4 py-2 text-sm",
    lg: "px-6 py-3 text-base"
  }.freeze

  def initialize(variant: :primary, size: :md, href: nil, method: nil, icon: nil,
                 disabled: false, confirm: nil, submit: false, type: "button", **options)
    @variant = variant.to_sym
    @size = size.to_sym
    @href = href
    @method = method
    @icon = icon
    @disabled = disabled
    @confirm = confirm
    @submit = submit
    @type = type
    @options = options
  end

  def call
    if @href
      link_tag
    elsif @submit
      submit_tag
    else
      button_tag_element
    end
  end

  private

  def css_classes
    [
      "inline-flex items-center justify-center gap-2 font-medium rounded-xl",
      "focus:outline-none focus:ring-2 focus:ring-offset-2",
      "transition-all duration-200",
      VARIANTS[@variant],
      SIZES[@size],
      @disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer",
      @options[:class]
    ].compact.join(" ")
  end

  def data_attributes
    attrs = @options.fetch(:data, {})
    attrs[:turbo_method] = @method if @method
    attrs[:turbo_confirm] = @confirm if @confirm
    attrs
  end

  def link_tag
    helpers.link_to @href, class: css_classes, data: data_attributes, id: @options[:id] do
      inner_content
    end
  end

  def submit_tag
    helpers.content_tag(:button, type: "submit", class: css_classes, disabled: @disabled,
                        id: @options[:id]) do
      inner_content
    end
  end

  def button_tag_element
    helpers.content_tag(:button, type: @type, class: css_classes, disabled: @disabled,
                        data: data_attributes, id: @options[:id]) do
      inner_content
    end
  end

  def inner_content
    safe_join([ icon_element, content ].compact)
  end

  def icon_element
    return nil unless @icon

    helpers.heroicon @icon, variant: :outline, options: { class: icon_size_class }
  end

  def icon_size_class
    case @size
    when :sm then "w-4 h-4"
    when :lg then "w-6 h-6"
    else "w-5 h-5"
    end
  end
end
