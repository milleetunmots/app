source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.5"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 7.0.0"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 5.6"
# Use SCSS for stylesheets
gem "sass-rails", "~> 6.0"
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker", "~> 5.4"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5.2"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# gem http use for multipart-form
gem "http"

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

gem 'google-api-client'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
  gem "rspec_junit_formatter"
  gem "rails-controller-testing"
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem "simplecov", require: false
  gem "factory_bot_rails"
  gem "faker"
  gem "database_cleaner-active_record"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.8"

  gem "annotate"
  gem "foreman"
  gem "rails-erd"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15"
  gem 'selenium-webdriver', '~> 4.11'
  gem "webmock"
  # ruby-prof
  gem "ruby-prof", ">= 0.17.0", require: false
  gem "stackprof", ">= 0.2.9", require: false
  gem "test-prof"
  gem 'rspec-sidekiq'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# ADMIN
gem "activeadmin", "~> 2.14.0"
gem "devise", "~> 4.9.0"
gem "cancancan"
gem "draper"
gem "arctic_admin"

# phones
gem "phonelib"

# other translations
gem "rails-i18n"
gem "devise-i18n"

# JS
gem "select2-rails"
gem "toastr-rails"

# Theming
gem "simple_form"
gem "bootstrap", "~> 4.3.0"

# errors tracking
gem "rollbar"

# global search
gem "pg_search"

# auditing
gem "paper_trail"

# PDF
gem "wkhtmltopdf-binary"
gem "wicked_pdf"

# soft deletion
gem "discard", "~> 1.0"

# date validation
gem "date_validator"

# tags
gem "acts-as-taggable-on", "~> 9.0"

# AS validations
gem "active_storage_validations"

# S3
gem "aws-sdk-s3", require: false

# image manipulations
gem "image_processing"

# ENV
gem "figaro"

# exports / spreadsheets
gem "fast_excel"
gem 'csv'
gem "roo", "~> 2.10.0"

# Asynchrone jobs
gem "sidekiq"
gem "sidekiq-scheduler"

# Zip file
gem "rubyzip", "~> 2.3.0"

# Rate limiting
gem 'rack-attack'

# Airtable
gem 'airrecord'

# to avoid compatibility issues, may not be necessary down the line
gem 'concurrent-ruby', '1.3.4'

# formerly standard ruby libraries no longer included by default
gem 'benchmark'
gem 'drb'


group :production do
  # for assets compilation
  gem "activerecord-nulldb-adapter"
end
