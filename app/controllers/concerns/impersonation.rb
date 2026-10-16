# Connexion de la coordination en tant qu'accompagnante : une substitution de vue
# côté serveur, sous le compte de l'opérateur. Pas de sign_in ni de sign_out de la
# cible, sinon sa 2FA serait contournée et ses cookies « se souvenir de moi » révoqués.
module Impersonation
  extend ActiveSupport::Concern

  SESSION_KEY = :impersonation_id

  included do
    helper_method :true_admin_user, :impersonating?, :impersonation
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

  def find_impersonation
    return if session[SESSION_KEY].blank?

    AdminUserImpersonation.ongoing.find_by(id: session[SESSION_KEY], operator_id: true_admin_user&.id)
  end
end
