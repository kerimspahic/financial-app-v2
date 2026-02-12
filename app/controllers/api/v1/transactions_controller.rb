module Api
  module V1
    class TransactionsController < BaseController
      include BalanceUpdatable
      include Pagy::Backend

      before_action :set_transaction, only: [ :show, :update, :destroy ]

      # GET /api/v1/transactions
      # Supports Ransack filtering: q[date_gteq], q[category_id_eq], q[transaction_type_eq], etc.
      # Supports pagination: page, per_page (default 25)
      def index
        scope = current_user.transactions.includes(:account, :category, :tags, :transaction_splits)
        scope = scope.where(account_id: params[:account_id]) if params[:account_id].present?

        # Ransack filtering
        q = scope.ransack(params[:q])
        q.sorts = "date desc" if q.sorts.empty?

        # Pagy pagination
        per = (params[:per_page] || 25).to_i.clamp(1, 100)
        pagy, transactions = pagy(q.result, limit: per, page: params[:page])

        render json: {
          data: transactions.map { |t| transaction_json(t) },
          meta: {
            current_page: pagy.page,
            total_pages: pagy.pages,
            total_count: pagy.count,
            per_page: pagy.limit
          }
        }
      end

      # GET /api/v1/transactions/:id
      def show
        render json: { data: transaction_json(@transaction) }
      end

      # POST /api/v1/transactions
      def create
        @transaction = current_user.transactions.build(transaction_params)
        if save_transaction_with_balance(@transaction)
          fire_webhooks("transaction.created", @transaction)
          render json: { data: transaction_json(@transaction.reload) }, status: :created
        else
          render_errors(@transaction)
        end
      end

      # PATCH /api/v1/transactions/:id
      def update
        old_transaction = @transaction.dup
        if update_transaction_with_balance(@transaction, old_transaction, transaction_params)
          fire_webhooks("transaction.updated", @transaction)
          render json: { data: transaction_json(@transaction.reload) }
        else
          render_errors(@transaction)
        end
      end

      # DELETE /api/v1/transactions/:id
      def destroy
        fire_webhooks("transaction.deleted", @transaction)
        destroy_transaction_with_balance(@transaction)
        head :no_content
      end

      # POST /api/v1/transactions/bulk_create
      def bulk_create
        results = { created: [], errors: [] }

        transactions_params = params.require(:transactions)
        transactions_params.each_with_index do |txn_params, index|
          transaction = current_user.transactions.build(
            txn_params.permit(:description, :amount, :transaction_type, :date, :notes, :account_id, :category_id, :destination_account_id, :clearing_status, :payee, :flag, :needs_review, :exclude_from_reports, tag_ids: [])
          )
          if save_transaction_with_balance(transaction)
            fire_webhooks("transaction.created", transaction)
            results[:created] << transaction_json(transaction)
          else
            results[:errors] << { index: index, errors: transaction.errors.full_messages }
          end
        end

        render json: {
          data: results[:created],
          errors: results[:errors],
          meta: { created_count: results[:created].size, error_count: results[:errors].size }
        }, status: results[:errors].any? ? :multi_status : :created
      end

      # PATCH /api/v1/transactions/bulk_update
      def bulk_update
        ids = params.require(:ids)
        updates = params.require(:updates).permit(:category_id, :clearing_status, :flag, :needs_review, :exclude_from_reports)

        transactions = current_user.transactions.where(id: ids)
        updated = transactions.update_all(updates.to_h)

        render json: { meta: { updated_count: updated } }
      end

      private

      def set_transaction
        @transaction = current_user.transactions.find(params[:id])
      end

      def transaction_params
        params.require(:transaction).permit(
          :description, :amount, :transaction_type, :date, :notes,
          :account_id, :category_id, :destination_account_id,
          :clearing_status, :payee, :flag, :needs_review, :exclude_from_reports,
          tag_ids: [],
          transaction_splits_attributes: [ :id, :category_id, :amount, :memo, :_destroy ]
        )
      end

      def transaction_json(transaction)
        {
          id: transaction.id,
          description: transaction.description,
          amount: transaction.amount.to_f,
          transaction_type: transaction.transaction_type,
          date: transaction.date.to_s,
          payee: transaction.payee,
          flag: transaction.flag,
          needs_review: transaction.needs_review,
          exclude_from_reports: transaction.exclude_from_reports,
          clearing_status: transaction.clearing_status,
          notes: transaction.notes,
          account: transaction.account ? { id: transaction.account.id, name: transaction.account.name } : nil,
          category: transaction.category ? { id: transaction.category.id, name: transaction.category.name } : nil,
          tags: transaction.tags.map { |tag| { id: tag.id, name: tag.name, color: tag.color } },
          splits: transaction.transaction_splits.map { |s| { id: s.id, category_id: s.category_id, amount: s.amount.to_f, memo: s.memo } },
          created_at: transaction.created_at,
          updated_at: transaction.updated_at
        }
      end

      def fire_webhooks(event_name, transaction)
        payload = transaction_json(transaction)
        current_user.webhooks.active.each do |webhook|
          WebhookDeliveryJob.perform_later(webhook.id, event_name, payload)
        end
      end
    end
  end
end
