module Settings
  class CategoriesController < BaseController
    before_action -> { set_section(:categories) }

    def show
    end
  end
end
