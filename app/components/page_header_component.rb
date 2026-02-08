class PageHeaderComponent < ApplicationComponent
  renders_one :actions

  def initialize(title:, subtitle: nil, **options)
    @title = title
    @subtitle = subtitle
    @options = options
  end
end
