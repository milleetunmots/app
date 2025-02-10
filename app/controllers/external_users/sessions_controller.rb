class ExternalUsers::SessionsController < Devise::SessionsController
  def after_sign_in_path_for(resource)
    external_dashboard_index_path
  end
end
