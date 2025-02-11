class External::DashboardController < External::BaseController
  authorize_resource class: false

  def index
    authorize! :read, :dashboard
    @external_user = current_user
    @children = Child.source_id_in(@external_user.source_id)
  end
end
