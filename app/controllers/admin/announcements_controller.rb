module Admin
  class AnnouncementsController < BaseController
    before_action -> { set_section(:announcements) }

    def index
    end
  end
end
