class TransactionsController < ApplicationController
  include BalanceUpdatable
  require_permission "manage_transactions"

  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @table_config = TableConfig.for_page("transactions")
    @saved_filters = current_user.saved_filters.for_page("transactions")

    scope = current_user.transactions.includes(:account, :category, :tags, transaction_splits: :category)

    # pg_search: full-text search
    scope = scope.search_all(params[:search]) if params[:search].present?

    # Ransack: filtering + sorting
    @q = scope.ransack(params[:q])
    @q.sorts = "date desc" if @q.sorts.empty?

    # Pagy: pagination
    @pagy, @transactions = pagy(@q.result, limit: user_per_page)

    # Resolve visible columns
    @visible_columns = resolve_visible_columns("transactions")

    @running_balances = compute_running_balances(@transactions) if @visible_columns.include?("balance")
  end

  def show
  end

  def new
    @transaction = current_user.transactions.build(date: Date.current)
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    apply_auto_categorization(@transaction) if @transaction.category_id.blank?
    if save_transaction_with_balance(@transaction)
      redirect_to transactions_path, notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @transaction.reconciled? && !params.dig(:transaction, :clearing_status).present?
      redirect_to transactions_path, alert: "Reconciled transactions cannot be modified. Change status to Cleared first."
      return
    end

    old_transaction = @transaction.dup
    if update_transaction_with_balance(@transaction, old_transaction, transaction_params)
      redirect_to transactions_path, notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @transaction.reconciled?
      redirect_to transactions_path, alert: "Reconciled transactions cannot be deleted."
      return
    end

    destroy_transaction_with_balance(@transaction)
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  def bulk_update
    ids = params[:transaction_ids] || []
    scope = current_user.transactions.where(id: ids).where.not(clearing_status: :reconciled)
    updates = {}
    updates[:category_id] = params[:bulk_category_id] if params[:bulk_category_id].present?
    updates[:clearing_status] = params[:bulk_clearing_status] if params[:bulk_clearing_status].present?
    scope.update_all(updates) if updates.any?
    redirect_to transactions_path, notice: "#{ids.size} transactions updated."
  end

  def bulk_destroy
    ids = params[:transaction_ids] || []
    transactions = current_user.transactions.where(id: ids).where.not(clearing_status: :reconciled)
    count = transactions.count
    transactions.find_each { |t| destroy_transaction_with_balance(t) }
    redirect_to transactions_path, notice: "#{count} transactions deleted."
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.expect(transaction: [ :description, :amount, :transaction_type, :date, :notes, :account_id, :category_id, :destination_account_id, :clearing_status, tag_ids: [], transaction_splits_attributes: [ :id, :category_id, :amount, :memo, :_destroy ] ])
  end

  def apply_auto_categorization(transaction)
    return unless transaction.description.present?

    rule = current_user.categorization_rules.ordered.find { |r| r.matches?(transaction.description) }
    transaction.category_id = rule.category_id if rule
  end

  def resolve_visible_columns(page_key)
    default_keys = @table_config.visible_column_keys
    user_settings = current_user.preference.table_settings&.dig(page_key, "visible_columns")
    user_settings.presence || default_keys
  end

  def compute_running_balances(transactions)
    return {} if transactions.empty?

    account_ids = transactions.map(&:account_id).uniq
    accounts_by_id = current_user.accounts.where(id: account_ids).index_by(&:id)
    account_running = {}

    # For each account, start with current balance and subtract the effect
    # of all transactions newer than the first one on this page
    newest_on_page = transactions.first
    account_ids.each do |aid|
      account = accounts_by_id[aid]
      next unless account

      newer_scope = current_user.transactions.where(account_id: aid)
        .where("date > ? OR (date = ? AND created_at > ?)", newest_on_page.date, newest_on_page.date, newest_on_page.created_at)

      income_sum = newer_scope.where(transaction_type: :income).sum(:amount)
      expense_sum = newer_scope.where(transaction_type: :expense).sum(:amount)
      transfer_out = newer_scope.where(transaction_type: :transfer).sum(:amount)

      newer_incoming = current_user.transactions.where(destination_account_id: aid, transaction_type: :transfer)
        .where("date > ? OR (date = ? AND created_at > ?)", newest_on_page.date, newest_on_page.date, newest_on_page.created_at)
      transfer_in = newer_incoming.sum(:amount)

      account_running[aid] = account.balance - income_sum + expense_sum + transfer_out - transfer_in
    end

    balances = {}
    transactions.each do |t|
      aid = t.account_id
      balances[t.id] = account_running[aid]

      if t.income?
        account_running[aid] -= t.amount
      elsif t.expense?
        account_running[aid] += t.amount
      elsif t.transfer?
        account_running[aid] += t.amount
      end
    end

    balances
  end
end
