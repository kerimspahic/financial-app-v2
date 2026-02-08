class SavingsGoalsController < ApplicationController
  require_permission "manage_savings_goals"

  def index
  end
end
