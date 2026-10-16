# Connexion de la coordination en tant qu'accompagnante : une substitution de vue
# côté serveur, sous le compte de l'opérateur. Pas de sign_in ni de sign_out de la
# cible, sinon sa 2FA serait contournée et ses cookies « se souvenir de moi » révoqués.
module Impersonation
  extend ActiveSupport::Concern

  SESSION_KEY = :impersonation_id

  included do
    helper_method :true_admin_user, :impersonating?, :impersonation

    # Pas sur les contrôleurs Devise : appeler Warden avant SessionsController#create
    # persisterait la session et contournerait sa gestion de la 2FA.
    before_action :end_invalid_impersonation, unless: :devise_controller?
  end

  # La cible pendant une connexion en tant que, l'opérateur sinon : les contrôles de rôle,
  # les scopes et l'Ability existants voient donc ce que voit la cible.
  def current_admin_user
    impersonation&.target || true_admin_user
  end

  def true_admin_user
    @true_admin_user ||= warden.authenticate(scope: :admin_user)
  end

  def impersonating?
    impersonation.present?
  end

  # La ligne n'est reconnue que si elle est ouverte et appartient bien à l'opérateur connecté.
  def impersonation
    return @impersonation if defined?(@impersonation)

    @impersonation = find_impersonation
  end

  private

  def end_impersonation
    impersonation&.finish!
    session.delete(SESSION_KEY)
  end

  # La requête qui découvre la fin n'est jamais rejouée sous le compte de l'opérateur :
  # elle visait la vue de la cible, dont il n'a pas les droits.
  def end_invalid_impersonation
    reason = invalid_impersonation_reason
    return if reason.nil?

    end_impersonation
    redirect_to admin_root_path, alert: t("impersonation.ended.#{reason}", name: impersonation.target.name)
  end

  def invalid_impersonation_reason
    return if impersonation.nil?
    return :operator_not_authorized unless impersonation.operator.can_impersonate?
    return :target_disabled if impersonation.target.is_disabled?

    :target_not_impersonable unless impersonation.target.impersonable?
  end

  def find_impersonation
    return if session[SESSION_KEY].blank?

    AdminUserImpersonation.ongoing.find_by(id: session[SESSION_KEY], operator_id: true_admin_user&.id)
  end
end
