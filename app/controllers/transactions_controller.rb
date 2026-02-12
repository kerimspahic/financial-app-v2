class TransactionsController < ApplicationController
  include BalanceUpdatable
  require_permission "manage_transactions"

  before_action :set_transaction, only: [ :show, :edit, :update, :destroy, :flag_transaction, :mark_reviewed, :inline_update, :remove_receipt ]

  def index
    @table_config = TableConfig.for_page("transactions")
    @saved_filters = current_user.saved_filters.for_page("transactions")

    scope = current_user.transactions.includes(:account, :category, :tags, :transaction_group, :receipts_attachments, transaction_splits: :category)

    # Quick filter: needs review
    scope = scope.needs_review if params[:review] == "true"

    # Quick filter: flagged only
    scope = scope.flagged if params[:flagged] == "true"

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

    # Stats for quick filter badges
    @needs_review_count = current_user.transactions.needs_review.count
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
      fire_webhooks("transaction.created", @transaction)
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
      fire_webhooks("transaction.updated", @transaction)
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

    transaction_data = webhook_payload(@transaction)
    destroy_transaction_with_balance(@transaction)
    fire_webhooks("transaction.deleted", nil, transaction_data)
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  def bulk_update
    ids = params[:transaction_ids] || []
    scope = current_user.transactions.where(id: ids).where.not(clearing_status: :reconciled)
    updates = {}
    updates[:category_id] = params[:bulk_category_id] if params[:bulk_category_id].present?
    updates[:clearing_status] = params[:bulk_clearing_status] if params[:bulk_clearing_status].present?
    updates[:flag] = params[:bulk_flag].present? ? params[:bulk_flag] : nil if params.key?(:bulk_flag)
    updates[:needs_review] = false if params[:bulk_mark_reviewed] == "true"
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

  def flag_transaction
    if params[:flag].present?
      @transaction.update(flag: params[:flag])
    else
      @transaction.update(flag: nil)
    end
    head :ok
  end

  def mark_reviewed
    @transaction.update(needs_review: params[:reviewed] != "true")
    head :ok
  end

  def inline_update
    if @transaction.reconciled?
      head :unprocessable_entity
      return
    end

    if @transaction.update(inline_transaction_params)
      @table_config = TableConfig.for_page("transactions")
      @visible_columns = resolve_visible_columns("transactions")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_#{@transaction.id}",
            partial: "transactions/row",
            locals: { t: @transaction, table_config: @table_config, visible_columns: @visible_columns }
          )
        end
        format.html { redirect_to transactions_path, notice: "Transaction updated." }
      end
    else
      head :unprocessable_entity
    end
  end

  def remove_receipt
    attachment = @transaction.receipts.find(params[:receipt_id])
    attachment.purge
    redirect_to transaction_path(@transaction), notice: "Receipt removed."
  end

  def export
    scope = current_user.transactions.includes(:account, :category, :tags, transaction_splits: :category)
    scope = scope.search_all(params[:search]) if params[:search].present?
    q = scope.ransack(params[:q])
    q.sorts = "date desc" if q.sorts.empty?
    transactions = q.result

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Date", "Payee", "Description", "Amount", "Type", "Category", "Account", "Tags", "Notes", "Flag", "Status", "Needs Review" ]
      transactions.each do |t|
        csv << [
          t.date.strftime("%Y-%m-%d"),
          t.payee,
          t.description,
          t.amount.to_f,
          t.transaction_type,
          t.split? ? t.transaction_splits.map { |s| "#{s.category.name}:#{s.amount}" }.join("; ") : t.category.name,
          t.account.name,
          t.tags.map(&:name).join(", "),
          t.notes,
          t.flag,
          t.clearing_status,
          t.needs_review
        ]
      end
    end

    send_data csv_data,
      filename: "transactions_#{Date.current.strftime('%Y%m%d')}.csv",
      type: "text/csv",
      disposition: "attachment"
  end

  def reconcile
    @accounts = current_user.accounts.active.ordered
    @account = current_user.accounts.find(params[:account_id]) if params[:account_id].present?

    if @account
      @unreconciled = current_user.transactions
        .where(account_id: @account.id)
        .where.not(clearing_status: :reconciled)
        .order(date: :desc, created_at: :desc)
    end
  end

  def complete_reconciliation
    account = current_user.accounts.find(params[:account_id])
    transaction_ids = params[:transaction_ids] || []
    statement_balance = BigDecimal(params[:statement_balance].to_s)

    transactions = current_user.transactions
      .where(id: transaction_ids, account_id: account.id)
      .where.not(clearing_status: :reconciled)

    transactions.update_all(clearing_status: :reconciled)

    redirect_to reconcile_transactions_path(account_id: account.id),
      notice: "Successfully reconciled #{transactions.count} transactions."
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.expect(transaction: [ :description, :amount, :transaction_type, :date, :notes, :account_id, :category_id, :destination_account_id, :clearing_status, :payee, :flag, :needs_review, :exclude_from_reports, :currency, :original_amount, :exchange_rate, :contra_category_id, :transaction_group_id, tag_ids: [], transaction_splits_attributes: [ :id, :category_id, :amount, :memo, :_destroy ], custom_fields: {}, receipts: [] ])
  end

  def inline_transaction_params
    params.expect(transaction: [ :description, :amount, :date, :category_id, :account_id, :payee ])
  end

  def apply_auto_categorization(transaction)
    return unless transaction.description.present? || transaction.payee.present?

    # Phase 1: Check categorization rules (expanded engine)
    rule = current_user.categorization_rules.active.ordered.find { |r| r.matches?(transaction) }
    if rule
      rule.apply_actions!(transaction)
      return if transaction.category_id.present?
    end

    # Phase 2: Smart categorization fallback (payee-based, then description similarity)
    if transaction.category_id.blank?
      result = SmartCategorizationService.new(current_user, transaction).suggest
      transaction.category_id = result[:category_id] if result && result[:confidence] >= 0.5
    end
  end

  def resolve_visible_columns(page_key)
    default_keys = @table_config.visible_column_keys
    user_settings = current_user.preference.table_settings&.dig(page_key, "visible_columns")
    user_settings.presence || default_keys
  end

  def fire_webhooks(event_name, transaction = nil, payload = nil)
    payload ||= webhook_payload(transaction)
    current_user.webhooks.active.each do |webhook|
      WebhookDeliveryJob.perform_later(webhook.id, event_name, payload)
    end
  end

  def webhook_payload(transaction)
    {
      id: transaction.id,
      description: transaction.description,
      amount: transaction.amount.to_f,
      transaction_type: transaction.transaction_type,
      date: transaction.date.to_s,
      account_id: transaction.account_id,
      category_id: transaction.category_id,
      payee: transaction.payee,
      flag: transaction.flag,
      needs_review: transaction.needs_review,
      clearing_status: transaction.clearing_status
    }
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
