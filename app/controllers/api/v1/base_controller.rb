module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      private

      def current_user
        warden.authenticate(scope: :user)
      end

      def warden
        request.env["warden"]
      end

      def authenticate_user!
        head :unauthorized unless current_user
      end

      def render_errors(resource)
        render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
