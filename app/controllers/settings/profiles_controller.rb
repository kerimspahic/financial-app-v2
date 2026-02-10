module Settings
  class ProfilesController < BaseController
    before_action -> { set_section(:profile) }

    def show
      @user = current_user
    end

    def update
      @user = current_user
      user_params = params.expect(user: [ :first_name, :last_name, :email, :current_password ])

      if email_changed?(user_params)
        update_with_password(user_params)
      else
        update_without_password(user_params.except(:current_password))
      end
    end

    private

    def email_changed?(user_params)
      user_params[:email].present? && user_params[:email] != current_user.email
    end

    def update_with_password(user_params)
      if @user.update_with_password(user_params)
        bypass_sign_in(@user)
        redirect_to settings_profile_path, notice: "Profile updated successfully."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def update_without_password(user_params)
      if @user.update(user_params)
        redirect_to settings_profile_path, notice: "Profile updated successfully."
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
