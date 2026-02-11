class CheckboxComponent < ApplicationComponent
  SIZES = {
    sm: { box: "w-3.5 h-3.5", label: "text-sm", desc: "text-xs", gap: "gap-2.5" },
    md: { box: "w-4 h-4", label: "text-sm", desc: "text-xs", gap: "gap-3" },
    lg: { box: "w-5 h-5", label: "text-base", desc: "text-sm", gap: "gap-3.5" }
  }.freeze

  VARIANTS = {
    default: "text-primary-500 focus:ring-primary-500/30",
    success: "text-success-500 focus:ring-success-500/30",
    danger: "text-danger-500 focus:ring-danger-500/30"
  }.freeze

  # @param form [ActionView::Helpers::FormBuilder, nil] Rails form builder (omit for standalone)
  # @param field [Symbol, nil] Model attribute name (used with form)
  # @param name [String, nil] HTML name attribute (standalone mode)
  # @param value [String, nil] HTML value attribute (standalone mode)
  # @param checked [Boolean, nil] Whether checked (standalone mode, form mode uses model state)
  # @param label [String, nil] Label text
  # @param description [String, nil] Description text below label
  # @param size [Symbol] :sm, :md, :lg
  # @param variant [Symbol] :default, :success, :danger
  # @param toggle [Boolean] Render as toggle switch instead of checkbox
  # @param disabled [Boolean] Disabled state
  # @param data [Hash] Stimulus data attributes
  def initialize(form: nil, field: nil, name: nil, value: nil, checked: nil,
                 label: nil, description: nil, size: :md, variant: :default,
                 toggle: false, disabled: false, data: {}, wrapper_class: nil, **options)
    @form = form
    @field = field
    @name = name
    @value = value
    @checked = checked
    @label = label
    @description = description
    @size = size.to_sym
    @variant = variant.to_sym
    @toggle = toggle
    @disabled = disabled
    @data = data
    @wrapper_class = wrapper_class
    @options = options
  end

  def form_mode?
    @form.present? && @field.present?
  end

  def size_config
    SIZES[@size] || SIZES[:md]
  end

  def checkbox_classes
    [
      size_config[:box],
      "rounded border-glass-border bg-transparent",
      VARIANTS[@variant],
      "focus:ring-2 focus:ring-offset-0 transition-colors cursor-pointer",
      "disabled:opacity-50 disabled:cursor-not-allowed",
      @options[:class]
    ].compact.join(" ")
  end

  def label_classes
    [
      size_config[:label],
      "font-medium text-text-primary",
      @disabled ? "opacity-50" : nil
    ].compact.join(" ")
  end

  def description_classes
    [
      size_config[:desc],
      "text-text-muted"
    ].join(" ")
  end

  def wrapper_classes
    [
      "flex items-start cursor-pointer group",
      size_config[:gap],
      @disabled ? "cursor-not-allowed" : nil,
      @wrapper_class
    ].compact.join(" ")
  end

  def toggle_track_classes
    "toggle-track relative inline-flex shrink-0 cursor-pointer rounded-full transition-colors duration-200 ease-in-out focus-within:ring-2 focus-within:ring-primary-500/30 focus-within:ring-offset-0"
  end

  def toggle_size
    case @size
    when :sm then { track: "h-4 w-7", thumb: "h-3 w-3", translate: "translate-x-3" }
    when :lg then { track: "h-7 w-12", thumb: "h-5.5 w-5.5", translate: "translate-x-5" }
    else { track: "h-5 w-9", thumb: "h-3.5 w-3.5", translate: "translate-x-4" }
    end
  end

  def toggle?
    @toggle
  end

  def checked?
    if form_mode?
      @form.object&.send(@field)
    else
      @checked
    end
  end

  def input_id
    if form_mode?
      "#{@form.object_name}_#{@field}"
    else
      @options[:id]
    end
  end
end
