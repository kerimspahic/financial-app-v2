class SettingsController < ApplicationController
  require_permission "manage_settings"

  def show
    @preference = current_user.preference
  end

  def update
    @preference = current_user.preference
    if @preference.update(preference_params)
      redirect_to settings_path, notice: "Settings saved."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def preference_params
    params.expect(user_preference: [ :theme_mode, :color_mode, :per_page ])
  end
end
