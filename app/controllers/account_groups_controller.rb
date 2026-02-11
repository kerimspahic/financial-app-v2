class AccountGroupsController < ApplicationController
  require_permission "manage_accounts"
  before_action :set_account_group, only: [ :edit, :update, :destroy ]

  def index
    redirect_to accounts_path
  end

  def new
    @account_group = current_user.account_groups.build
  end

  def create
    @account_group = current_user.account_groups.build(account_group_params)
    if @account_group.save
      redirect_to accounts_path, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account_group.update(account_group_params)
      redirect_to accounts_path, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account_group.destroy
    redirect_to accounts_path, notice: "Group was successfully deleted."
  end

  private

  def set_account_group
    @account_group = current_user.account_groups.find(params[:id])
  end

  def account_group_params
    params.expect(account_group: [ :name ])
  end
end
