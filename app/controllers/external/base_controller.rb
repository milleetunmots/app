class External::BaseController < ActionController::Base
  before_action :authenticate_external_user!
  before_action :check_authorization

  def access_denied(exception)
    redirect_to new_external_user_session_url, alert: exception.message
  end

  private

  def current_user
    current_external_user
  end

  def check_authorization
    resource = controller_name.to_sym
    authorize! :read, resource
  rescue CanCan::AccessDenied => e
    redirect_to new_external_user_session_path, alert: e.message
  end
end
