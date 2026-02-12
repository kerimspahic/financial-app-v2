class TransactionGroupsController < ApplicationController
  require_permission "manage_transactions"

  before_action :set_transaction_group, only: [ :show, :destroy, :add_transaction, :remove_transaction ]

  def index
    @transaction_groups = current_user.transaction_groups
      .includes(:transactions)
      .order(created_at: :desc)
  end

  def show
    @transactions = @transaction_group.transactions
      .includes(:account, :category, :tags)
      .order(date: :desc)
  end

  def new
    @transaction_group = current_user.transaction_groups.build
  end

  def create
    @transaction_group = current_user.transaction_groups.build(transaction_group_params)

    if @transaction_group.save
      redirect_to transaction_group_path(@transaction_group), notice: "Transaction group created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction_group.destroy
    redirect_to transaction_groups_path, notice: "Transaction group deleted."
  end

  def add_transaction
    transaction = current_user.transactions.find(params[:transaction_id])
    transaction.update(transaction_group: @transaction_group)
    redirect_to transaction_group_path(@transaction_group), notice: "Transaction added to group."
  end

  def remove_transaction
    transaction = current_user.transactions.find(params[:transaction_id])
    transaction.update(transaction_group: nil)
    redirect_to transaction_group_path(@transaction_group), notice: "Transaction removed from group."
  end

  private

  def set_transaction_group
    @transaction_group = current_user.transaction_groups.find(params[:id])
  end

  def transaction_group_params
    params.expect(transaction_group: [ :name, :group_type ])
  end
end
