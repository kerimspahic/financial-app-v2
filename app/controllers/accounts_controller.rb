class AccountsController < ApplicationController
  require_permission "manage_accounts"
  before_action :set_account, only: [ :show, :edit, :update, :destroy, :archive, :unarchive, :reconcile, :confirm_reconcile, :performance, :merge, :perform_merge ]

  def index
    @accounts = current_user.accounts.active.ordered.includes(:account_group)
    @archived_accounts = current_user.accounts.archived.ordered
    @account_groups = current_user.account_groups.ordered.includes(:accounts)

    # Net worth computation
    nw_accounts = current_user.accounts.active.included_in_net_worth
    @total_assets = nw_accounts.where(account_type: [ :checking, :savings, :cash, :investment, :property, :vehicle ].map { |t| Account.account_types[t] }).sum(:balance)
    @total_liabilities = nw_accounts.where(account_type: Account.account_types[:credit_card]).sum(:balance)
    @net_worth = @total_assets - @total_liabilities

    # Sparkline data: last 30 days of balance snapshots per account
    account_ids = @accounts.map(&:id)
    @sparkline_data = AccountBalanceSnapshot
      .where(account_id: account_ids)
      .where(date: 30.days.ago.to_date..Date.current)
      .order(:date)
      .group_by(&:account_id)
      .transform_values { |snapshots| snapshots.map(&:balance).map(&:to_f) }

    # Balance % change this month
    @balance_changes = {}
    start_of_month = Date.current.beginning_of_month
    month_start_snapshots = AccountBalanceSnapshot
      .where(account_id: account_ids)
      .where("date <= ?", start_of_month)
      .order(Arel.sql("account_id, date DESC"))
      .select("DISTINCT ON (account_id) account_id, balance")
    prior_balances = {}
    month_start_snapshots.each do |snap|
      current_balance = @accounts.detect { |a| a.id == snap.account_id }&.balance
      prior_balances[snap.account_id] = snap.balance
      next unless current_balance && !snap.balance.zero?
      @balance_changes[snap.account_id] = ((current_balance - snap.balance) / snap.balance * 100).round(1)
    end

    # Stat card changes
    prior_assets = 0
    prior_liabilities = 0
    @accounts.each do |acct|
      snap_balance = prior_balances[acct.id]
      next unless snap_balance
      if acct.asset?
        prior_assets += snap_balance
      elsif acct.liability?
        prior_liabilities += snap_balance
      end
    end
    prior_net_worth = prior_assets - prior_liabilities
    @net_worth_change = prior_net_worth.zero? ? nil : ((@net_worth - prior_net_worth) / prior_net_worth * 100).round(1)
    @assets_change = prior_assets.zero? ? nil : ((@total_assets - prior_assets) / prior_assets * 100).round(1)
    @liabilities_change = prior_liabilities.zero? ? nil : ((@total_liabilities - prior_liabilities) / prior_liabilities * 100).round(1)

    # Group by mode
    @group_mode = params[:group_by] || "group"
    if @group_mode == "institution"
      @institution_groups = @accounts.group_by { |a| a.bank_name.presence || "Other" }
    end
  end

  def show
    if turbo_frame_modal?
      @transactions = @account.transactions.recent.includes(:category).limit(5)
    else
      @pagy, @transactions = pagy(@account.transactions.recent.includes(:category), limit: user_per_page)

      # Analytics data
      @balance_snapshots = @account.balance_snapshots.for_period(6.months.ago.to_date, Date.current).order(:date)

      current_month = Date.current
      month_range = current_month.beginning_of_month..current_month.end_of_month
      account_transactions = @account.transactions.where(date: month_range)
      @account_monthly_income = account_transactions.where(transaction_type: :income).sum(:amount)
      @account_monthly_expenses = account_transactions.where(transaction_type: :expense).sum(:amount)

      @account_category_breakdown = @account.transactions
        .where(transaction_type: :expense, date: month_range)
        .joins(:category)
        .group("categories.name", "categories.color")
        .sum(:amount)
        .map { |(name, color), amount| { name: name, color: color, amount: amount } }
        .sort_by { |c| -c[:amount] }

      @total_transactions = @account.transactions.count
      @avg_transaction = @account.transactions.average(:amount)&.round(2) || 0
      @oldest_transaction = @account.transactions.minimum(:date)
    end
  end

  def new
    @account = current_user.accounts.build
  end

  def create
    @account = current_user.accounts.build(account_params)
    if @account.save
      redirect_to accounts_path, notice: "Account was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_path = params[:return_to] == "show" ? account_path(@account) : accounts_path
      redirect_to redirect_path, notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    redirect_to accounts_path, notice: "Account was successfully deleted."
  end

  def archive
    @account.archive!
    redirect_to accounts_path, notice: "#{@account.name} has been archived."
  end

  def unarchive
    @account.unarchive!
    redirect_to accounts_path, notice: "#{@account.name} has been restored."
  end

  def reorder
    params[:positions].each do |id, position|
      current_user.accounts.find(id).update(position: position)
    end
    head :ok
  end

  def reconcile
    @unreconciled = @account.transactions.where.not(clearing_status: :reconciled).recent.includes(:category)
  end

  def confirm_reconcile
    transaction_ids = params[:transaction_ids] || []
    @account.transactions.where(id: transaction_ids).update_all(clearing_status: Transaction.clearing_statuses[:reconciled])
    redirect_to account_path(@account), notice: "#{transaction_ids.size} transactions reconciled."
  end

  def performance
    snapshots = @account.balance_snapshots.where("date >= ?", 12.months.ago.to_date).order(:date)
    if snapshots.size >= 2
      base = snapshots.first.balance.to_f
      @date_labels = snapshots.map { |s| s.date.strftime("%b %Y") }
      @portfolio_series = snapshots.map { |s| base.zero? ? 0 : ((s.balance.to_f - base) / base * 100).round(2) }
    else
      @date_labels = []
      @portfolio_series = []
    end

    benchmark = Benchmark.find_by(name: "S&P 500")
    if benchmark && snapshots.size >= 2
      months = snapshots.map { |s| s.date.strftime("%Y-%m") }.uniq
      cum = 1.0
      @benchmark_series = months.map do |m|
        r = benchmark.monthly_returns[m] || 0
        cum *= (1 + r / 100.0)
        ((cum - 1) * 100).round(2)
      end
    else
      @benchmark_series = []
    end
  end

  def merge
    @other_accounts = current_user.accounts.active.where.not(id: @account.id).ordered
  end

  def perform_merge
    target = current_user.accounts.find(params[:target_account_id])
    merger = AccountMerger.new(@account, target)
    merger.merge!
    redirect_to accounts_path, notice: "'#{@account.name}' has been merged into '#{target.name}'."
  rescue ActiveRecord::RecordNotFound
    redirect_to merge_account_path(@account), alert: "Target account not found."
  rescue => e
    redirect_to merge_account_path(@account), alert: e.message
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  end

  def account_params
    if action_name == "create"
      params.expect(account: [ :name, :account_type, :balance, :currency, :description, :balance_goal, :account_group_id, :credit_limit, :interest_rate, :exclude_from_net_worth, :bank_name, :account_number_masked, :iban, :icon_emoji, :original_loan_amount, :loan_term_months ])
    else
      params.expect(account: [ :name, :account_type, :currency, :description, :balance_goal, :account_group_id, :credit_limit, :interest_rate, :exclude_from_net_worth, :bank_name, :account_number_masked, :iban, :icon_emoji, :original_loan_amount, :loan_term_months ])
    end
  end
end
