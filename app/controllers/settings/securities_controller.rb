module Settings
  class SecuritiesController < BaseController
    before_action -> { set_section(:security) }

    def show
      @minimum_password_length = Devise.password_length.min
    end

    def update
      password_params = params.expect(user: [ :current_password, :password, :password_confirmation ])

      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to settings_security_path, notice: "Password updated successfully."
      else
        @minimum_password_length = Devise.password_length.min
        render :show, status: :unprocessable_entity
      end
    end

    def destroy_account
      current_user.destroy
      redirect_to root_path, notice: "Your account has been deleted. We're sorry to see you go."
    end
  end
end
