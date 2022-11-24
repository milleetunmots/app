Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  get "inscription", to: "children#new", as: :new_child
  get "inscription1", to: "children#new"
  get "inscription2", to: "children#new"
  get "inscription3", to: "children#new"

  post "inscription", to: "children#create", as: :children
  post "inscription1", to: "children#create", as: :children1
  post "inscription2", to: "children#create", as: :children2
  post "inscription3", to: "children#create", as: :children3
  get "inscrit", to: "children#created", as: :created_child

  scope "c/:id/:security_code" do
    get "/", to: "children#edit", as: :edit_child
    patch "/", to: "children#update", as: :update_child
  end

  scope "w/:parent_id/:workshop_id" do
    get "/", to: "workshop_participation#edit", as: :edit_workshop_participation
    patch "/", to: "workshop_participation#update", as: :update_workshop_participation
  end

  get "mis-a-jour", to: "children#updated", as: :updated_child

  get "mis-a-jour-invitation", to: "workshop_participation#updated", as: :updated_workshop_participation

  get "r/:id/:security_code", to: "redirection#visit", as: :visit_redirection

  get "spot_hit/status", to: "events#update_status"
  get "spot_hit/response", to: "events#spot_hit_response"
  get "spot_hit/stop", to: "events#spot_hit_stop"

  get "parent/:id/first_child", to: "parents#first_child"

  post "/typeform/webhooks", to: 'typeform#webhooks'

  resources :events, only: [:index, :create]

  resources :children_support_modules, only: [:edit, :update] do
    get "updated", on: :collection
  end

  root to: redirect("/admin")

end
