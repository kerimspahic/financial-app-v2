class TableComponent < ApplicationComponent
  renders_one :header
  renders_one :body
  renders_one :empty_state

  def initialize(striped: false, hoverable: true, **options)
    @striped = striped
    @hoverable = hoverable
    @options = options
  end

  def table_classes
    [
      "min-w-full divide-y divide-border",
      @options[:class]
    ].compact.join(" ")
  end

  def row_classes
    classes = []
    classes << "even:bg-surface-hover" if @striped
    classes << "hover:bg-surface-hover" if @hoverable
    classes.join(" ")
  end
end
