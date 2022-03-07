Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  get "inscription", to: "children#new", as: :new_child
  get "inscription1", to: "children#new1"
  get "inscription2", to: "children#new2"
  get "inscription3", to: "children#new3"
  get "inscription_link", to: "children#new2"
  get "inscription_pro", to: "children#new3"

  post "inscription", to: "children#create", as: :children
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

  resources :events, only: [:index, :create]

  root to: redirect("/admin")

end
