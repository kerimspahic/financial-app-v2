class EmptyStateComponent < ApplicationComponent
  def initialize(title:, description: nil, icon: nil, action_text: nil, action_url: nil, action_data: {}, **options)
    @title = title
    @description = description
    @icon = icon
    @action_text = action_text
    @action_url = action_url
    @action_data = action_data
    @options = options
  end
end
