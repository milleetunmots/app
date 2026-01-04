if ENV['SENTRY_DSN']
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Add data like request headers and IP for users,
    # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
    config.send_default_pii = true

    # Set tracing sample rate (optional, for performance monitoring)
    # config.traces_sample_rate = 0.1

    # Filter bot probing errors (same logic as Rollbar)
    config.before_send = lambda do |event, hint|
      exception = hint[:exception]

      if exception.is_a?(ActionController::RoutingError)
        # Ignore bot probing for security holes (WordPress, config files, etc)
        patterns = [
          # Extensions communes des bots
          /No route matches \[(GET|POST|PUT|PATCH|DELETE)\] "\/.*\.(php|xml|yml|txt|png|asp|aspx|cgi|env|sql|bak|log|ini|conf)"$/,
          # Chemins WordPress courants
          /No route matches \[(GET|POST|PUT|PATCH|DELETE)\] "\/wp-(login|admin|content|includes|json)/,
          # POST sur la racine (souvent des bots)
          /No route matches \[POST\] "\/"$/,
          # Autres chemins suspects courants
          /No route matches \[(GET|POST|PUT|PATCH|DELETE)\] "\/(admin|phpmyadmin|pma|adminer|\.git|\.env|config)/
        ]

        return nil if patterns.any? { |pattern| exception.message.match?(pattern) }
      end

      event
    end
  end
end
