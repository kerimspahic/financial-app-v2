module Admin
  class RolesController < BaseController
    before_action -> { set_section(:roles) }
    before_action :set_role, only: [ :edit, :update, :destroy ]

    def index
      @roles = Role.includes(:users, :permissions).order(:name)
    end

    def new
      @role = Role.new
      @permissions = Permission.order(:key)
    end

    def create
      @role = Role.new(role_params)
      if @role.save
        sync_permissions
        redirect_to admin_roles_path, notice: "Role created successfully."
      else
        @permissions = Permission.order(:key)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @permissions = Permission.order(:key)
    end

    def update
      if @role.update(role_params)
        sync_permissions
        redirect_to admin_roles_path, notice: "Role updated successfully."
      else
        @permissions = Permission.order(:key)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @role.users.any?
        redirect_to admin_roles_path, alert: "Cannot delete a role that is assigned to users."
      else
        @role.destroy
        redirect_to admin_roles_path, notice: "Role deleted successfully."
      end
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.expect(role: [ :name, :description ])
    end

    def sync_permissions
      permission_ids = (params[:permission_ids] || []).map(&:to_i)
      @role.permission_ids = permission_ids
    end
  end
end
