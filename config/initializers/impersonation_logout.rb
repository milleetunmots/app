# Ferme la ligne de journal ouverte quand l'opérateur se déconnecte : la session
# est vidée juste après, plus rien ne pourrait la fermer ensuite.
#
# Warden::Manager est le middleware d'authentification sur lequel repose Devise.
# Son hook before_logout s'exécute à chaque warden.logout, donc à chaque sign_out
# de Devise, quel qu'en soit l'appelant : surcharger SessionsController#destroy
# ne couvrirait que le bouton « Se déconnecter ». Le bloc reçoit le compte qui se
# déconnecte (user) et le Warden::Proxy de la requête (auth), qui donne la session.
Warden::Manager.before_logout do |user, auth, _options|
  next unless user.is_a?(AdminUser)

  impersonation_id = auth.raw_session&.fetch(Impersonation::SESSION_KEY, nil)
  next if impersonation_id.blank?

  AdminUserImpersonation.ongoing.find_by(id: impersonation_id, operator_id: user.id)&.finish!
end
