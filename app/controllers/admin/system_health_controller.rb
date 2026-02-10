module Admin
  class SystemHealthController < BaseController
    before_action -> { set_section(:system_health) }

    def show
    end
  end
end
