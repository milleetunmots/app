Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  resources :children, only: [:new, :create]

  get 'inscription', to: 'children#new'

  root to: redirect('/admin')

end
