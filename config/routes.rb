Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  get 'inscription', to: 'children#new', as: :new_child
  get 'inscription1', to: 'children#new1'
  get 'inscription2', to: 'children#new2'
  get 'inscription3', to: 'children#new3'

  post 'inscription', to: 'children#create', as: :children
  get 'inscrit', to: 'children#created', as: :created_child

  scope 'c/:id/:security_code' do
    get '/', to: 'children#edit', as: :edit_child
    patch '/', to: 'children#update', as: :update_child
  end
  get 'mis-a-jour', to: 'children#updated', as: :updated_child

  get 'r/:id/:security_code', to: 'redirection#visit', as: :visit_redirection

  get 'spot_hit/status', to: 'events#update_status'
  get 'spot_hit/response', to: 'events#spot_hit_response'

  resources :events, only: [:index, :create]

  root to: redirect('/admin')

end
