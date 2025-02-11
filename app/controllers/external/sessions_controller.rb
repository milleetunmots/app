class External::SessionsController < External::BaseController
  skip_authorization_check
  skip_before_action :require_login, only: [:new, :create]

  def new
    @user = ExternalUser.new
  end

  def create
    user = ExternalUser.find_by(email: params[:email])

    if user&.authenticated?(params[:password])
      sign_in(user)
      redirect_to external_dashboard_index_path, notice: "Connexion réussie."
    else
      flash.now[:alert] = "Email ou mot de passe invalide."
      render :new
    end
  end

  def destroy
    sign_out
    redirect_to external_sign_in_path, notice: "Déconnexion réussie."
  end
end
