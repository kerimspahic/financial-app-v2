module Api
  module V1
    class SavingsGoalsController < BaseController
      def index
        render json: { data: [], message: "Coming soon" }
      end
    end
  end
end
