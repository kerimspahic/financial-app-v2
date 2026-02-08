class ModalComponent < ApplicationComponent
  renders_one :trigger

  SIZES = {
    sm: "max-w-md",
    md: "max-w-lg",
    lg: "max-w-2xl"
  }.freeze

  def initialize(title: nil, size: :md, turbo_frame: nil, **options)
    @title = title
    @size = size.to_sym
    @turbo_frame = turbo_frame
    @options = options
  end

  def size_class
    SIZES[@size] || SIZES[:md]
  end

  def turbo_frame?
    @turbo_frame.present?
  end

  def turbo_frame_id
    @turbo_frame
  end
end
