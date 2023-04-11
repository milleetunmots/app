[![Maintainability](https://api.codeclimate.com/v1/badges/366f7968ef64ea677c66/maintainability)](https://codeclimate.com/github/milleetunmots/app/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/366f7968ef64ea677c66/test_coverage)](https://codeclimate.com/github/milleetunmots/app/test_coverage)
[![CircleCI](https://circleci.com/gh/milleetunmots/app/tree/develop.svg?style=svg)](https://circleci.com/gh/milleetunmots/app/tree/develop)

# 1001mots
## Which versions ?
* Ruby version : 2.6.6
* Rails version : 6.0.3.6
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
## Description
Cette plateforme est utilisée pour organiser le suivi d'enfants de bas âge par les équipes de l'association 1001mots après leurs inscriptions par leurs parents ou par les professionnels de PMI partenaires. À part les ateliers qui ont lieu en présentiel, le reste de l'accompagnement se fait à distance, par l'envoie de livres par la Poste, de SMS et d'appels de spécialistes. Le contenu des messages, les informations liées aux ateliers et celles recueillies lors des appels sont gérés grâce à la plateforme.
## Principaux cas d'utilisation
* Inscription d'un enfant et son suivi
* Suivi des enfants par une spécialiste



