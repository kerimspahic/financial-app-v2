module Settings
  class BaseController < ApplicationController
    private

    def set_section(section)
      @settings_section = section
    end
  end
end
