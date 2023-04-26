# 5 requests per second per IP
Rack::Attack.throttle('limit webhooks', limit: 5, period: 1) do |request|
  if request.path.start_with?('/spot_hit/')
    request.ip
  end
end
