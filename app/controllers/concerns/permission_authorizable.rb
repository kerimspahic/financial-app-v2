module PermissionAuthorizable
  extend ActiveSupport::Concern

  class_methods do
    def require_permission(permission_key, **options)
      before_action(**options) do
        authorize_permission!(permission_key)
      end
    end
  end

  private

  def authorize_permission!(permission_key)
    unless current_user&.has_permission?(permission_key)
      respond_to do |format|
        format.html { redirect_to root_path, alert: "You don't have permission to access this feature." }
        format.json { head :forbidden }
      end
    end
  end
end
