module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :edit, :update, :toggle_active ]

    def index
      users = User.includes(:roles).order(created_at: :desc)

      if params[:search].present?
        users = users.where(
          "email ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q",
          q: "%#{params[:search]}%"
        )
      end

      users = users.where(active: params[:active] == "true") if params[:active].present?

      if params[:role].present?
        users = users.joins(:roles).where(roles: { name: params[:role] })
      end

      @pagy, @users = pagy(users, limit: 20)
      @roles = Role.order(:name)
    end

    def edit
      @roles = Role.order(:name)
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User updated successfully."
      else
        @roles = Role.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot disable your own account."
        return
      end

      @user.update!(active: !@user.active?)
      status_text = @user.active? ? "enabled" : "disabled"
      redirect_to admin_users_path, notice: "User account #{status_text}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: [ :first_name, :last_name, :email ])
    end
  end
end
