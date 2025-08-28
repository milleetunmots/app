require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mots
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.active_job.queue_adapter = :sidekiq
    config.time_zone = 'Europe/Paris'
    config.active_record.yaml_column_permitted_classes = [Date, Time, Symbol, ActsAsTaggableOn::TagList, ActsAsTaggableOn::DefaultParser]
    config.active_record.legacy_connection_handling = false
    config.active_record.partial_inserts = true
    config.active_support.disable_to_s_conversion = true
  end
end
