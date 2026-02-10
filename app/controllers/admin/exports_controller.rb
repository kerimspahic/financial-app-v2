module Admin
  class ExportsController < BaseController
    before_action -> { set_section(:exports) }

    def index
    end
  end
end
