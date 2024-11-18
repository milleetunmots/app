[![Maintainability](https://api.codeclimate.com/v1/badges/366f7968ef64ea677c66/maintainability)](https://codeclimate.com/github/milleetunmots/app/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/366f7968ef64ea677c66/test_coverage)](https://codeclimate.com/github/milleetunmots/app/test_coverage)
[![CircleCI](https://circleci.com/gh/milleetunmots/app/tree/develop.svg?style=svg)](https://circleci.com/gh/milleetunmots/app/tree/develop)

# 1001mots
## Which versions ?
* Ruby version : 3.3.6
* Rails version : 6.1
## How to get set up locally ?
### Prerequisite
* bundler gem installed
### Configuration
* ```bundle install```
* ```cp config/database.yml.example config/database.yml```
* change values to match your local postgreSQL configuration
* ```cp config/application.yml.example config/application.yml```
* change values to enable third-party tools
* ```rails db:create```
* ```rails db:migrate```
* ```rails db:seed```
### Run a local version
```rails s```
### Run tests
```bundle exec rspec ./spec```
### Run with sidekiq
```bin/dev```
