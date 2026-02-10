module Admin
  class DashboardController < BaseController
    before_action -> { set_section(:dashboard) }

    def index
      @total_users = User.count
      @active_users = User.where(active: true).count
      @disabled_users = User.where(active: false).count
      @total_transactions = Transaction.count
      @total_accounts = Account.count
      @total_roles = Role.count
      @recent_users = User.order(created_at: :desc).limit(5)
    end
  end
end
