class TransactionsController < ApplicationController
  include BalanceUpdatable
  require_permission "manage_transactions"

  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @table_config = TableConfig.for_page("transactions")
    @saved_filters = current_user.saved_filters.for_page("transactions")

    scope = current_user.transactions.includes(:account, :category, :tags)

    # pg_search: full-text search
    scope = scope.search_all(params[:search]) if params[:search].present?

    # Ransack: filtering + sorting
    @q = scope.ransack(params[:q])
    @q.sorts = "date desc" if @q.sorts.empty?

    # Pagy: pagination
    @pagy, @transactions = pagy(@q.result, limit: user_per_page)

    # Resolve visible columns
    @visible_columns = resolve_visible_columns("transactions")
  end

  def show
  end

  def new
    @transaction = current_user.transactions.build(date: Date.current)
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    if save_transaction_with_balance(@transaction)
      redirect_to @transaction, notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    old_transaction = @transaction.dup
    if update_transaction_with_balance(@transaction, old_transaction, transaction_params)
      redirect_to @transaction, notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    destroy_transaction_with_balance(@transaction)
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.expect(transaction: [ :description, :amount, :transaction_type, :date, :notes, :account_id, :category_id ])
  end

  def resolve_visible_columns(page_key)
    default_keys = @table_config.visible_column_keys
    user_settings = current_user.preference.table_settings&.dig(page_key, "visible_columns")
    user_settings.presence || default_keys
  end
end
