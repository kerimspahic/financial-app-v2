class ModalComponent < ApplicationComponent
  renders_one :trigger

  SIZES = {
    sm: "max-w-md",
    md: "max-w-lg",
    lg: "max-w-2xl"
  }.freeze

  def initialize(title: nil, size: :md, **options)
    @title = title
    @size = size.to_sym
    @options = options
  end

  def size_class
    SIZES[@size] || SIZES[:md]
  end
end
