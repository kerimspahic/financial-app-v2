class DropdownComponent < ApplicationComponent
  renders_one :trigger
  renders_many :items

  ALIGNMENTS = {
    left: "left-0",
    right: "right-0"
  }.freeze

  def initialize(align: :right, **options)
    @align = align.to_sym
    @options = options
  end

  def align_class
    ALIGNMENTS[@align] || ALIGNMENTS[:right]
  end
end
