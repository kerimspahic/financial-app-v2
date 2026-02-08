module Api
  module V1
    class BudgetsController < BaseController
      before_action :set_budget, only: [ :update, :destroy ]

      def index
        month = (params[:month] || Date.current.month).to_i
        year = (params[:year] || Date.current.year).to_i
        @budgets = current_user.budgets.where(month: month, year: year).includes(:category)
        render json: @budgets.map { |b|
          b.as_json(include: :category).merge(spent: b.spent, remaining: b.remaining, percent_used: b.percent_used)
        }
      end

      def create
        @budget = current_user.budgets.build(budget_params)
        if @budget.save
          render json: @budget, status: :created
        else
          render_errors(@budget)
        end
      end

      def update
        if @budget.update(budget_params)
          render json: @budget
        else
          render_errors(@budget)
        end
      end

      def destroy
        @budget.destroy
        head :no_content
      end

      private

      def set_budget
        @budget = current_user.budgets.find(params[:id])
      end

      def budget_params
        params.require(:budget).permit(:amount, :month, :year, :category_id)
      end
    end
  end
end
