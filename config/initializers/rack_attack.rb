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

# Throttle du login par IP : 3 tentatives / 60 s.
Rack::Attack.throttle('login/ip', limit: 3, period: 60) do |request|
  request.ip if request.post? && request.path == '/admin/login'
end

# Throttle du login par email : protège un compte ciblé depuis plusieurs IP.
Rack::Attack.throttle('login/email', limit: 5, period: 60) do |request|
  if request.post? && request.path == '/admin/login'
    email = request.params.dig('admin_user', 'email')
    email.to_s.downcase.strip.presence
  end
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

# 5 requests per second per IP
Rack::Attack.throttle('limit webhooks', limit: 3, period: 1) do |request|
  if request.path.start_with?('/spot_hit/')
    request.ip
  end
end
