class DebtAccountsController < ApplicationController
  require_permission "manage_debt_accounts"

  def index
  end
end
