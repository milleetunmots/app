Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  get 'inscription', to: 'children#new', as: :new_child
  post 'inscription', to: 'children#create', as: :children
  get 'inscrit', to: 'children#created', as: :created_child

  root to: redirect('/admin')

end
