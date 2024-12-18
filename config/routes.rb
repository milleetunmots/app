require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  get 'status', to: 'application#status'

  get 'inscription', to: 'children#new', as: :new_child
  get 'inscription1', to: 'children#new', as: :new_child1
  get 'inscriptioncaf', to: 'children#new', as: :new_caf_registration
  get 'inscription3', to: 'children#new', as: :new_pmi_registration
  get 'inscription4', to: 'children#new', as: :new_bao_registration
  get 'inscription5', to: 'children#new', as: :new_local_partner_registration

  # Créer formulaire bao
  # Créer formulaire partenaires locaux

  post 'inscription', to: 'children#create', as: :children
  post 'inscription1', to: 'children#create', as: :children1
  post 'inscriptioncaf', to: 'children#create', as: :caf_registration
  post 'inscription3', to: 'children#create', as: :pmi_registration
  post 'inscription4', to: 'children#create', as: :boa_registration
  post 'inscription5', to: 'children#create', as: :local_partner_registration
  get 'inscrit', to: 'children#created', as: :created_child

  scope 'c/:id/:security_code' do
    get '/', to: 'children#edit', as: :edit_child
    patch '/', to: 'children#update', as: :update_child
  end

  scope 'w/:parent_id/:parent_security_code/:workshop_id' do
    get '/', to: 'workshop_participation#edit', as: :edit_workshop_participation
    patch '/', to: 'workshop_participation#update', as: :update_workshop_participation
  end

  get 'confirm-end-support/:child_support_id/:parent1_sc', to: 'child_supports#confirm_end_support', as: :confirm_end_support
  get 'child-support-updated-at/:child_support_id', to: 'child_supports#updated_at', as: :child_support_updated_at
  get 'child-support-supporter_first_name/:child_support_id', to: 'child_supports#supporter_first_name', as: :child_support_supporter_first_name
  get 'child-support-call-goal/:child_support_id/:call_index', to: 'child_supports#call_goal', as: :child_support_call_goals
  get 'child-support-task-reporter/:task_title/', to: 'child_supports#task_reporter', as: :child_support_task_reporter
  get 'child-support-task-treated-by', to: 'child_supports#task_treated_by', as: :child_support_task_treated_by
  get 'mis-a-jour', to: 'children#updated', as: :updated_child
  get 'mis-a-jour-invitation', to: 'workshop_participation#updated', as: :updated_workshop_participation
  get 'r/:id/:security_code', to: 'redirection#visit', as: :visit_redirection
  get 'spot_hit/status', to: 'events#update_status'
  get 'spot_hit/response', to: 'events#spot_hit_response'
  get 'spot_hit/stop', to: 'events#spot_hit_stop'
  get 's/:id', to: 'children_support_modules#edit', as: :children_support_module_link
  get 'c3/sf', to: 'child_supports#call3_speaking_form', as: :call3_speaking_form
  get 'c3/of', to: 'child_supports#call3_observing_form', as: :call3_observing_form
  get 'c0', to: 'child_supports#call0_form', as: :call0_form
  get 'parents_answer/:survey_id/:question_id', to: 'parents_answers#new', as: :new_parents_answer
  post '/typeform/webhooks', to: 'typeform#webhooks'

  resources :events, only: %i[index create]

  resources :children_support_modules, only: %i[edit update] do
    get 'updated', on: :member
  end

  resources :parents do
    member { get :current_child_source }
  end

  resources :admin_users do
    member do
      put :disable
      put :activate
    end
  end

  resources :sources do
    collection do
      get :caf_by_utm
      get :friends
      get :local_partner_has_department
    end
  end

  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :api do
    namespace :v1 do
      get 'child_support_count', to: 'child_supports#child_support_count'
    end
  end

  root to: redirect('/admin')
end
