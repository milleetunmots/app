Clearance.configure do |config|
  config.routes = false
  config.user_model = ExternalUser
  config.mailer_sender = "reply@example.com"
  config.rotate_csrf_on_sign_in = true
  config.allow_sign_up = false
  config.cookie_domain = :all
  config.cookie_expiration = ->(cookies) { 1.year.from_now.utc }
  config.secure_cookie = Rails.env.production?
end
