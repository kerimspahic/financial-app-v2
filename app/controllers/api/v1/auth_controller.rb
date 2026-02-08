module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [ :sign_in, :sign_up ]

      def sign_in
        user = User.find_by(email: params[:email])
        if user&.valid_password?(params[:password])
          sign_in_user(user)
          render json: {
            user: { id: user.id, email: user.email, first_name: user.first_name, last_name: user.last_name },
            message: "Signed in successfully."
          }
        else
          render json: { error: "Invalid email or password." }, status: :unauthorized
        end
      end

      def sign_up
        user = User.new(sign_up_params)
        if user.save
          sign_in_user(user)
          render json: {
            user: { id: user.id, email: user.email, first_name: user.first_name, last_name: user.last_name },
            message: "Signed up successfully."
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def sign_out
        if current_user
          current_user.update(jti: SecureRandom.uuid)
          render json: { message: "Signed out successfully." }
        else
          head :unauthorized
        end
      end

      private

      def sign_up_params
        params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end

      def sign_in_user(user)
        warden.set_user(user, scope: :user)
      end
    end
  end
end
