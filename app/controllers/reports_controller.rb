class ReportsController < ApplicationController
  require_permission "view_reports"

  def index
  end
end
