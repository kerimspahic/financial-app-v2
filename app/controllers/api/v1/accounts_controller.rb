module Api
  module V1
    class AccountsController < BaseController
      before_action :set_account, only: [ :show, :update, :destroy ]

      def index
        @accounts = current_user.accounts
        render json: @accounts
      end

      def show
        render json: @account
      end

      def create
        @account = current_user.accounts.build(account_params)
        if @account.save
          render json: @account, status: :created
        else
          render_errors(@account)
        end
      end

      def update
        if @account.update(account_params)
          render json: @account
        else
          render_errors(@account)
        end
      end

      def destroy
        @account.destroy
        head :no_content
      end

      private

      def set_account
        @account = current_user.accounts.find(params[:id])
      end

      def account_params
        params.permit(:name, :account_type, :balance, :currency)
      end
    end
  end
end
