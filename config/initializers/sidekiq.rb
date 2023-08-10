if defined?(Sidekiq)
  sidekiq_config = { url: ENV['REDIS_URL'] }
  Sidekiq[:max_retries] = 5

  Sidekiq.configure_server do |config|
    config.redis = sidekiq_config
  end

  Sidekiq.configure_client do |config|
    config.redis = sidekiq_config
  end
end
