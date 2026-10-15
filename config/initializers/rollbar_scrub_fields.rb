# Rollbar n'utilise pas Rails.application.config.filter_parameters : ses champs masqués sont à lui.
# Sans cette ligne, une erreur survenue pendant l'enregistrement d'une fiche enverrait le texte sensible
# en clair dans les paramètres de la requête.
# `preconfigure` plutôt que `configure` : ce dernier active Rollbar (enabled: true) et charge ses plugins,
# alors que ce fichier doit rester sans effet sur l'état de Rollbar, lequel dépend de rollbar.rb.
Rollbar.preconfigure do |config|
  config.scrub_fields |= [:sensitive_information]
end
