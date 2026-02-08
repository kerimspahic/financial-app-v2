class EmptyStateComponent < ApplicationComponent
  def initialize(title:, description: nil, icon: nil, action_text: nil, action_url: nil, **options)
    @title = title
    @description = description
    @icon = icon
    @action_text = action_text
    @action_url = action_url
    @options = options
  end
end
