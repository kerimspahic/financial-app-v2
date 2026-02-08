class TransactionsController < ApplicationController
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def index
    @transactions = current_user.transactions.recent.includes(:account, :category)
    @transactions = @transactions.where(account_id: params[:account_id]) if params[:account_id].present?
    @transactions = @transactions.where(category_id: params[:category_id]) if params[:category_id].present?
    @transactions = @transactions.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
  end

  def show
  end

  def new
    @transaction = current_user.transactions.build(date: Date.current)
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    if @transaction.save
      update_account_balance(@transaction)
      redirect_to @transaction, notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    old_transaction = @transaction.dup
    if @transaction.update(transaction_params)
      reverse_account_balance(old_transaction)
      update_account_balance(@transaction)
      redirect_to @transaction, notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    reverse_account_balance(@transaction)
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.expect(transaction: [ :description, :amount, :transaction_type, :date, :notes, :account_id, :category_id ])
  end

  def update_account_balance(transaction)
    account = transaction.account
    if transaction.income?
      account.increment!(:balance, transaction.amount)
    elsif transaction.expense?
      account.decrement!(:balance, transaction.amount)
    end
  end

  def reverse_account_balance(transaction)
    account = transaction.account
    if transaction.income?
      account.decrement!(:balance, transaction.amount)
    elsif transaction.expense?
      account.increment!(:balance, transaction.amount)
    end
  end
end
