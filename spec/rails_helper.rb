require "simplecov"

SimpleCov.start "rails"

# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
ENV['INITIAL_TYPEFORM_NAME'] = 'typeform_name_id'
ENV['INITIAL_TYPEFORM_CHILD_COUNT'] = 'typeform_child_count_id'
ENV['INITIAL_TYPEFORM_ALREADY_WORKING_WITH'] = 'typeform_already_working_with_id'
ENV['INITIAL_TYPEFORM_BOOKS_QUANTITY'] = 'typeform_books_quantity_id'
ENV['INITIAL_TYPEFORM_MOST_PRESENT_PARENT'] = 'typeform_most_present_parent_id'
ENV['INITIAL_TYPEFORM_OTHER_PARENT_PHONE'] = 'typeform_other_parent_phone_id'
ENV['INITIAL_TYPEFORM_OTHER_PARENT_DEGREE'] = 'typeform_other_parent_degree_id'
ENV['INITIAL_TYPEFORM_OTHER_PARENT_DEGREE_IN_FRANCE'] = 'typeform_other_parent_degree_in_france_id'
ENV['INITIAL_TYPEFORM_DEGREE'] = 'typeform_degree_id'
ENV['INITIAL_TYPEFORM_DEGREE_IN_FRANCE'] = 'typeform_degree_in_france_id'
ENV['INITIAL_TYPEFORM_READING_FREQUENCY'] = 'typeform_reading_frequency_id'
ENV['INITIAL_TYPEFORM_TV_FREQUENCY'] = 'typeform_tv_frequency_id'
ENV['INITIAL_TYPEFORM_IS_BILINGUAL'] = 'typeform_is_bilingual_id'
ENV['INITIAL_TYPEFORM_HELP_MY_CHILD_TO_LEARN_IS_IMPORTANT'] = 'typeform_help_my_child_to_learn_id_important_id'
ENV['INITIAL_TYPEFORM_WOULD_LIKE_TO_DO_MORE'] = 'typeform_would_like_to_do_more_id'
ENV['INITIAL_TYPEFORM_WOULD_LIKE_TO_RECEIVE_ADVICES'] = 'typeform_would_like_to_receive_advices_id'
ENV['INITIAL_TYPEFORM_PARENTAL_CONTEXTS'] = 'typeform_parental_contexts_id'
ENV["MODULE_ZERO_FEATURE_START"] ||= "01/09/2023"
ENV['DISENGAGEMENT_FEATURE_START_DATE'] ||= "01/09/2023"
ENV['BLOCKED_REGISTRATION_PATHS'] ||= ""
ENV['NOT_SUPPORTED_LINK'] ||= "http://google.fr"
ENV['API_TOKEN'] ||= "valid token"
ENV['AIRCALL_API_ID'] ||= "valid token"
ENV['AIRCALL_API_TOKEN'] ||= "valid token"

require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "test_prof/recipes/rspec/let_it_be"
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Block all external requests
  WebMock.disable_net_connect!(allow_localhost: true)

  config.before(:each) do
    stub_request(:post, "https://www.spot-hit.fr/api/envoyer/sms").to_return(status: 200, body: "{}", headers: {})
  end

  # Skip DatabaseCleaner's safeguard in order to be able to connect to a database using an URL (ie. Docker container)
  if Rails.env.test?
    DatabaseCleaner.allow_remote_database_url = true
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
