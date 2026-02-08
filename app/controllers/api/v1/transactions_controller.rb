module Api
  module V1
    class TransactionsController < BaseController
      before_action :set_transaction, only: [ :show, :update, :destroy ]

      def index
        @transactions = current_user.transactions.recent.includes(:account, :category)
        @transactions = @transactions.where(account_id: params[:account_id]) if params[:account_id].present?
        @transactions = @transactions.where(category_id: params[:category_id]) if params[:category_id].present?
        render json: @transactions, include: [ :account, :category ], methods: [ :transaction_type ]
      end

      def show
        render json: @transaction, include: [ :account, :category ]
      end

      def create
        @transaction = current_user.transactions.build(transaction_params)
        if @transaction.save
          render json: @transaction, status: :created
        else
          render_errors(@transaction)
        end
      end

      def update
        if @transaction.update(transaction_params)
          render json: @transaction
        else
          render_errors(@transaction)
        end
      end

      def destroy
        @transaction.destroy
        head :no_content
      end

      private

      def set_transaction
        @transaction = current_user.transactions.find(params[:id])
      end

      def transaction_params
        params.require(:transaction).permit(:description, :amount, :transaction_type, :date, :notes, :account_id, :category_id)
      end
    end
  end
end
