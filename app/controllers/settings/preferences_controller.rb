module Settings
  class PreferencesController < BaseController
    before_action -> { set_section(:preferences) }

    def show
      @preference = current_user.preference
    end

    def update
      @preference = current_user.preference
      if @preference.update(preference_params)
        redirect_to settings_preferences_path, notice: "Preferences saved."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def preference_params
      params.expect(user_preference: [ :per_page, :accounting_mode ])
    end
  end
end
