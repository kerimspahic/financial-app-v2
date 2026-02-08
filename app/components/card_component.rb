class CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer

  def initialize(padding: true, **options)
    @padding = padding
    @options = options
  end

  def css_classes
    [
      "glass rounded-2xl shadow-lg hover-lift",
      @options[:class]
    ].compact.join(" ")
  end
end
