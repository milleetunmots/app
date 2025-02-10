class External::DashboardController < External::BaseController
  before_action :authenticate_external_user!

  def index
    # Logique pour la page spécifique
  end
end
