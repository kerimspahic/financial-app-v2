class BillsController < ApplicationController
  require_permission "manage_bills"

  def index
  end
end
