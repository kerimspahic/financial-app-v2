class InsightsController < ApplicationController
  require_permission "view_insights"

  def index
  end
end
