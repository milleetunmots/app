require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  get "inscription", to: "children#new", as: :new_child   # formulaire site
  get "inscription1", to: "children#new", as: :new_child1 # formulaire site
  get "inscription2", to: "children#new", as: :new_child2 # formulaire caf, à modifier
  get "inscription3", to: "children#new", as: :new_pmi_registration # fomulaire pmi, à modifier

  # Créer formulaire bao
  # Créer formulaire partenaire locaux

  post "inscription", to: "children#create", as: :children
  post "inscription1", to: "children#create", as: :children1
  post "inscription2", to: "children#create", as: :children2
  post "inscription3", to: "children#create", as: :pmi_registration
  get "inscrit", to: "children#created", as: :created_child

  scope "c/:id/:security_code" do
    get "/", to: "children#edit", as: :edit_child
    patch "/", to: "children#update", as: :update_child
  end

  scope "w/:parent_id/:parent_security_code/:workshop_id" do
    get "/", to: "workshop_participation#edit", as: :edit_workshop_participation
    patch "/", to: "workshop_participation#update", as: :update_workshop_participation
  end

  get "mis-a-jour", to: "children#updated", as: :updated_child

  get "mis-a-jour-invitation", to: "workshop_participation#updated", as: :updated_workshop_participation

  get "r/:id/:security_code", to: "redirection#visit", as: :visit_redirection

  get "spot_hit/status", to: "events#update_status"
  get "spot_hit/response", to: "events#spot_hit_response"
  get "spot_hit/stop", to: "events#spot_hit_stop"

  post "/typeform/webhooks", to: 'typeform#webhooks'

  resources :events, only: [:index, :create]

  resources :children_support_modules, only: [:edit, :update] do
    get "updated", on: :member
  end

  get "s/:id", to: 'children_support_modules#edit', as: :children_support_module_link

  authenticate :admin_user do
    mount Sidekiq::Web => "/sidekiq"
  end

  resources :parents do
    member { get :current_child }
  end

  resources :sources do
    collection do
      get :caf_by_utm
      get :friends
    end
  end

  root to: redirect("/admin")
end
