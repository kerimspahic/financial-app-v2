class AccountSharesController < ApplicationController
  require_permission "manage_accounts"
  before_action :set_account, except: :accept

  def index
    @shares = @account.account_shares.includes(:user).order(:created_at)
  end

  def create
    email = params[:email]&.strip&.downcase
    user = User.find_by(email: email)

    if user.nil?
      redirect_to account_shares_path(@account), alert: "No user found with email '#{email}'."
      return
    end

    if user.id == current_user.id
      redirect_to account_shares_path(@account), alert: "You already own this account."
      return
    end

    share = @account.account_shares.build(
      user: user,
      permission_level: params[:permission_level] || :viewer,
      invitation_email: email
    )

    if share.save
      redirect_to account_shares_path(@account), notice: "#{email} invited as #{share.permission_level}."
    else
      redirect_to account_shares_path(@account), alert: share.errors.full_messages.join(", ")
    end
  end

  def destroy
    share = @account.account_shares.find(params[:id])
    share.destroy
    redirect_to account_shares_path(@account), notice: "Access revoked."
  end

  def accept
    share = AccountShare.find_by(invitation_token: params[:token])
    if share.nil?
      redirect_to root_path, alert: "Invalid or expired invitation."
      return
    end

    if share.user_id != current_user.id
      redirect_to root_path, alert: "This invitation is for a different account."
      return
    end

    share.accept!
    redirect_to account_path(share.account), notice: "You now have #{share.permission_level} access to #{share.account.name}."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
  end
end
