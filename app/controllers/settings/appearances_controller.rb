module Settings
  class AppearancesController < BaseController
    before_action -> { set_section(:appearance) }

    def show
      @preference = current_user.preference
    end

    def update
      @preference = current_user.preference
      if @preference.update(appearance_params)
        redirect_to settings_appearance_path, notice: "Appearance settings saved."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def update_theme
      @preference = current_user.preference
      if @preference.update(theme_params)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def appearance_params
      params.expect(user_preference: [ :theme_mode, :color_mode ])
    end

    def theme_params
      params.permit(:theme_mode, :color_mode)
    end
  end
end
