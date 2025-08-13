class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!
  

  layout :layout_by_resource

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username, :email]) # Add :username here, keep :email if you allow login by email too
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :firstname,:surname,:email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :firstname,:surname])
  end

  private

  def layout_by_resource
    devise_controller? ? "devise" : "application"
  end

  
end
