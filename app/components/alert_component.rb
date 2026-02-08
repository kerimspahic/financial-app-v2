class AlertComponent < ApplicationComponent
  VARIANTS = {
    success: { bg: "bg-success-50 border-success-500", text: "text-success-700", icon: "check-circle" },
    info: { bg: "bg-info-50 border-info-500", text: "text-info-700", icon: "information-circle" },
    warning: { bg: "bg-warning-50 border-warning-500", text: "text-warning-700", icon: "exclamation-triangle" },
    danger: { bg: "bg-danger-50 border-danger-500", text: "text-danger-700", icon: "x-circle" }
  }.freeze

  def initialize(variant: :info, dismissable: true, timeout: 5, **options)
    @variant = variant.to_sym
    @dismissable = dismissable
    @timeout = timeout
    @options = options
  end

  def config
    VARIANTS[@variant] || VARIANTS[:info]
  end

  def css_classes
    [
      "p-4 rounded-xl border-l-4 flex items-start gap-3 glass animate-fade-up",
      config[:bg],
      @options[:class]
    ].compact.join(" ")
  end

  def text_class
    config[:text]
  end

  def icon_name
    config[:icon]
  end

  def dismissable?
    @dismissable
  end

  def render?
    content.present?
  end
end
