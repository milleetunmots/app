# Jusqu'ici rack-attack utilisait Rails.cache, soit :null_store en test : le
# throttle des webhooks Spot Hit ci-dessous ne comptait donc jamais. Le store
# dédié le rend actif et ferait échouer les specs qui enchaînent les requêtes.
Rack::Attack.enabled = !Rails.env.test?

# Store dédié à rack-attack : compteurs partagés entre workers Puma / serveurs.
# On ne modifie PAS config.cache_store global.
Rack::Attack.cache.store =
  if ENV['REDIS_URL'].present?
    ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV['REDIS_URL'],
      namespace: 'rack_attack',
      error_handler: ->(method:, returning:, exception:) { Rails.logger.warn("[rack-attack] cache error: #{exception.class}") } # rubocop:disable Lint/UnusedBlockArgument
    )
  else
    ActiveSupport::Cache::MemoryStore.new
  end

# La route Devise est `POST /admin/login(.:format)` : comparer le chemin exact
# laisserait `/admin/login.json` (ou un slash final) contourner le throttle.
login_path_prefix = '/admin/login'

# Throttle du login par IP : 15 tentatives / 60 s.
# Le compteur inclut les connexions réussies (le middleware s'exécute avant
# Rails et ignore l'issue du login) et une IP est partagée par tout un bureau
# ou tout un opérateur mobile : le seuil doit rester loin de l'usage normal.
# La vraie protection par compte est le throttle login/email ci-dessous.
Rack::Attack.throttle('login/ip', limit: 15, period: 60) do |request|
  request.ip if request.post? && request.path.start_with?(login_path_prefix)
end

# Throttle du login par email : protège un compte ciblé depuis plusieurs IP.
Rack::Attack.throttle('login/email', limit: 5, period: 60) do |request|
  if request.post? && request.path.start_with?(login_path_prefix)
    email = request.params.dig('admin_user', 'email')
    email.to_s.downcase.strip.presence
  end
end

# Throttle de la double authentification : couvre la vérification du code et
# son renvoi. Le modèle limite déjà à 5 tentatives par code et 1 renvoi par
# minute ; cette règle borne l'attaquant qui enchaînerait les sessions en
# attente pour multiplier les essais.
Rack::Attack.throttle('two_factor/ip', limit: 10, period: 60) do |request|
  request.ip if request.post? && request.path.start_with?('/admin/two_factor')
end

# Réponse renvoyée quand une limite est atteinte.
Rack::Attack.throttled_responder = ->(request) do
  retry_after = (request.env['rack.attack.match_data'] || {})[:period]
  [
    429,
    { 'Content-Type' => 'text/plain; charset=utf-8', 'Retry-After' => retry_after.to_s },
    ["Trop de tentatives. Réessayez dans #{retry_after} secondes.\n"]
  ]
end

# 3 requêtes / seconde / IP (abaissé de 5 à 3 en mai 2023, cf. d62ecfe3)
Rack::Attack.throttle('limit webhooks', limit: 3, period: 1) do |request|
  if request.path.start_with?('/spot_hit/')
    request.ip
  end
end

# Sans trace, impossible de savoir si une limite se déclenche réellement.
# C'est surtout vrai pour les webhooks Spot Hit : aucun mécanisme ne rejoue un
# callback refusé, donc chaque 429 est une donnée définitivement perdue
# (statut de délivrance, réponse d'un parent, ou demande de STOP).
ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _id, payload|
  request = payload[:request]
  rule = request.env['rack.attack.matched']
  Rails.logger.warn(
    "[rack-attack] throttled rule=#{rule} " \
    "path=#{request.path} ip=#{request.ip}"
  )

  # Rollbar uniquement pour les throttles de login : les 429 sur les webhooks
  # Spot Hit sont trop fréquents et satureraient le quota du plan gratuit.
  if rule.to_s.start_with?('login/')
    Rollbar.warning('Rack::Attack throttle triggered', rule: rule, path: request.path, ip: request.ip)
  end
end
