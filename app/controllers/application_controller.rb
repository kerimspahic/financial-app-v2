class ApplicationController < ActionController::Base
  include ::Pagy::Method
  include PermissionAuthorizable

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :turbo_frame_modal?

  protected

  def turbo_frame_modal?
    turbo_frame_request_id == "modal"
  end

  def user_per_page
    current_user&.preference&.per_page || 25
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end
end
