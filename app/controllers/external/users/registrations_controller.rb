class External::Users::RegistrationsController < Devise::RegistrationsController
  before_action :authorize_admin!, only: [:new, :create]

  private

  def authorize_admin!
    unless current_external_user&.pmi_admin?
      redirect_to external_dashboard_path, alert: "Accès refusé."
    end
  end

  def sign_up_params
    params.require(:external_user).permit(:email, :password, :password_confirmation, :role, :source_id)
  end

  def account_update_params
    params.require(:external_user).permit(:email, :password, :password_confirmation, :current_password)
  end
end
