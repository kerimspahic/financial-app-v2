class RecurringTransactionsController < ApplicationController
  require_permission "manage_recurring_transactions"

  def index
  end
end
