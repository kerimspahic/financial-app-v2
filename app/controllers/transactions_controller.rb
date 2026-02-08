class TransactionsController < ApplicationController
  include BalanceUpdatable
  require_permission "manage_transactions"

  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    transactions = current_user.transactions.recent.includes(:account, :category)
    transactions = transactions.where(account_id: params[:account_id]) if params[:account_id].present?
    transactions = transactions.where(category_id: params[:category_id]) if params[:category_id].present?
    transactions = transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
    @pagy, @transactions = pagy(transactions, limit: user_per_page)
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
end
