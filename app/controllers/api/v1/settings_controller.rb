module Api
  module V1
    class SettingsController < BaseController
      def show
        preference = current_user.preference
        render json: {
          theme_mode: preference.theme_mode,
          color_mode: preference.color_mode
        }
      end

      def update
        preference = current_user.preference
        if preference.update(preference_params)
          render json: {
            theme_mode: preference.theme_mode,
            color_mode: preference.color_mode
          }
        else
          render_errors(preference)
        end
      end

      private

      def preference_params
        params.expect(user_preference: [ :theme_mode, :color_mode ])
      end
    end
  end
end
