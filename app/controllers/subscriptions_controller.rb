class SubscriptionsController < ApplicationController
  require_permission "manage_subscriptions"

  def index
  end
end
