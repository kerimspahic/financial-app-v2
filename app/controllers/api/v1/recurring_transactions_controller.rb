module Api
  module V1
    class RecurringTransactionsController < BaseController
      include Pagy::Backend

      before_action :set_recurring_transaction, only: [ :show, :update, :destroy, :toggle ]

      # GET /api/v1/recurring_transactions
      def index
        scope = current_user.recurring_transactions.includes(:account, :category)

        q = scope.ransack(params[:q])
        q.sorts = "next_occurrence asc" if q.sorts.empty?

        per = (params[:per_page] || 25).to_i.clamp(1, 100)
        pagy, recurring_transactions = pagy(q.result, limit: per, page: params[:page])

        render json: {
          data: recurring_transactions.map { |rt| recurring_transaction_json(rt) },
          meta: {
            current_page: pagy.page,
            total_pages: pagy.pages,
            total_count: pagy.count,
            per_page: pagy.limit
          }
        }
      end

      # GET /api/v1/recurring_transactions/:id
      def show
        render json: { data: recurring_transaction_json(@recurring_transaction) }
      end

      # POST /api/v1/recurring_transactions
      def create
        @recurring_transaction = current_user.recurring_transactions.build(recurring_transaction_params)
        if @recurring_transaction.save
          render json: { data: recurring_transaction_json(@recurring_transaction) }, status: :created
        else
          render_errors(@recurring_transaction)
        end
      end

      # PATCH /api/v1/recurring_transactions/:id
      def update
        if @recurring_transaction.update(recurring_transaction_params)
          render json: { data: recurring_transaction_json(@recurring_transaction) }
        else
          render_errors(@recurring_transaction)
        end
      end

      # DELETE /api/v1/recurring_transactions/:id
      def destroy
        @recurring_transaction.destroy
        head :no_content
      end

      # PATCH /api/v1/recurring_transactions/:id/toggle
      def toggle
        @recurring_transaction.update!(active: !@recurring_transaction.active?)
        render json: { data: recurring_transaction_json(@recurring_transaction) }
      end

      private

      def set_recurring_transaction
        @recurring_transaction = current_user.recurring_transactions.find(params[:id])
      end

      def recurring_transaction_params
        params.require(:recurring_transaction).permit(
          :description, :amount, :transaction_type, :frequency,
          :next_occurrence, :account_id, :category_id, :active
        )
      end

      def recurring_transaction_json(rt)
        {
          id: rt.id,
          description: rt.description,
          amount: rt.amount.to_f,
          transaction_type: rt.transaction_type,
          frequency: rt.frequency,
          next_occurrence: rt.next_occurrence.to_s,
          active: rt.active?,
          last_generated_at: rt.last_generated_at,
          overdue: rt.overdue?,
          days_until_next: rt.days_until_next,
          account: rt.account ? { id: rt.account.id, name: rt.account.name } : nil,
          category: rt.category ? { id: rt.category.id, name: rt.category.name } : nil,
          created_at: rt.created_at,
          updated_at: rt.updated_at
        }
      end
    end
  end
end
