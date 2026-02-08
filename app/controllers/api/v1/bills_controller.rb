module Api
  module V1
    class BillsController < BaseController
      def index
        render json: { data: [], message: "Coming soon" }
      end
    end
  end
end
