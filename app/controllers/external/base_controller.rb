class External::BaseController < ActionController::Base
  include Clearance::Controller

  layout 'external'

  before_action :require_login
  check_authorization

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to external_dashboard_index_path, alert: "Accès refusé : vous n'avez pas la permission d'effectuer cette action."
  end

  private

  def url_after_denied_access_when_signed_out
    external_sign_in_path
  end
end
