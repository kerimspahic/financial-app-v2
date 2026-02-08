module Api
  module V1
    class CategoriesController < BaseController
      before_action :set_category, only: [ :update, :destroy ]

      def index
        @categories = current_user.categories.order(:category_type, :name)
        render json: @categories
      end

      def create
        @category = current_user.categories.build(category_params)
        if @category.save
          render json: @category, status: :created
        else
          render_errors(@category)
        end
      end

      def update
        if @category.update(category_params)
          render json: @category
        else
          render_errors(@category)
        end
      end

      def destroy
        @category.destroy
        head :no_content
      end

      private

      def set_category
        @category = current_user.categories.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:name, :category_type, :color, :icon)
      end
    end
  end
end
