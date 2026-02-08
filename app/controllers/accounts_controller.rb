class AccountsController < ApplicationController
  require_permission "manage_accounts"
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = current_user.accounts
  end

  def show
    if turbo_frame_modal?
      @transactions = @account.transactions.recent.includes(:category).limit(5)
    else
      @pagy, @transactions = pagy(@account.transactions.recent.includes(:category), limit: user_per_page)
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

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  end

  def account_params
    if action_name == "create"
      params.expect(account: [ :name, :account_type, :balance, :currency ])
    else
      params.expect(account: [ :name, :account_type, :currency ])
    end
  end
end
