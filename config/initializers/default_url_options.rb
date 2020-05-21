Rails.application.routes.default_url_options.merge!(
  Rails.application.config.action_mailer.default_url_options || {}
)
