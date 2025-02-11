class External::TotoController < External::BaseController
  authorize_resource class: false

  def index
    authorize! :read, :toto
    @external_user = current_user
  end
end
