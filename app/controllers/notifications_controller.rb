class NotificationsController < ApplicationController
  require_permission "view_notifications"

  def index
  end
end
