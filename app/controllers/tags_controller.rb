class TagsController < ApplicationController
  require_permission "manage_tags"

  def index
  end
end
