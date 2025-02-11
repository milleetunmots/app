class External::DashboardController < External::BaseController
  authorize_resource class: false

  def index
    authorize! :read, :dashboard
    @external_user = current_user
  end
end
