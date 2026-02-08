class IntegrationsController < ApplicationController
  require_permission "manage_integrations"

  def index
  end
end
