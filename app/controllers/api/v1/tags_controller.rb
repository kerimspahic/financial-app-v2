module Api
  module V1
    class TagsController < BaseController
      before_action :set_tag, only: [ :show, :update, :destroy ]

      # GET /api/v1/tags
      def index
        tags = current_user.tags.order(:name)

        render json: {
          data: tags.map { |tag| tag_json(tag) }
        }
      end

      # GET /api/v1/tags/:id
      def show
        render json: { data: tag_json(@tag) }
      end

      # POST /api/v1/tags
      def create
        @tag = current_user.tags.build(tag_params)
        if @tag.save
          render json: { data: tag_json(@tag) }, status: :created
        else
          render_errors(@tag)
        end
      end

      # PATCH /api/v1/tags/:id
      def update
        if @tag.update(tag_params)
          render json: { data: tag_json(@tag) }
        else
          render_errors(@tag)
        end
      end

      # DELETE /api/v1/tags/:id
      def destroy
        @tag.destroy
        head :no_content
      end

      private

      def set_tag
        @tag = current_user.tags.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:name, :color)
      end

      def tag_json(tag)
        {
          id: tag.id,
          name: tag.name,
          color: tag.color,
          transaction_count: tag.transaction_tags.count,
          created_at: tag.created_at,
          updated_at: tag.updated_at
        }
      end
    end
  end
end
