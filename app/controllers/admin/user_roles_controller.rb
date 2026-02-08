module Admin
  class UserRolesController < BaseController
    before_action :set_user

    def update
      role_ids = params[:role_ids] || []
      @user.role_ids = role_ids.map(&:to_i)
      redirect_to edit_admin_user_path(@user), notice: "Roles updated successfully."
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end
  end
end
