class RecurringTransactionsController < ApplicationController
  require_permission "manage_recurring_transactions"
  before_action :set_recurring_transaction, only: [ :edit, :update, :destroy, :toggle ]

  def index
    @active_recurring = current_user.recurring_transactions.active.includes(:account, :category).order(:next_occurrence)
    @inactive_recurring = current_user.recurring_transactions.where(active: false).includes(:account, :category).order(:next_occurrence)
  end

  def new
    @recurring_transaction = current_user.recurring_transactions.build(next_occurrence: Date.current)
  end

  def create
    @recurring_transaction = current_user.recurring_transactions.build(recurring_transaction_params)
    if @recurring_transaction.save
      redirect_to recurring_transactions_path, notice: "Recurring transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @recurring_transaction.update(recurring_transaction_params)
      redirect_to recurring_transactions_path, notice: "Recurring transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recurring_transaction.destroy
    redirect_to recurring_transactions_path, notice: "Recurring transaction was successfully deleted."
  end

  def toggle
    @recurring_transaction.update!(active: !@recurring_transaction.active)
    status = @recurring_transaction.active? ? "activated" : "paused"
    redirect_to recurring_transactions_path, notice: "#{@recurring_transaction.description} #{status}."
  end

  def detected
    service = RecurringDetectionService.new(current_user)
    @candidates = service.detect
  end

  private

  def set_recurring_transaction
    @recurring_transaction = current_user.recurring_transactions.find(params[:id])
  end

  def recurring_transaction_params
    params.expect(recurring_transaction: [ :description, :amount, :transaction_type, :frequency, :next_occurrence, :account_id, :category_id ])
  end
end
