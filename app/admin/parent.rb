ActiveAdmin.register Parent do

  decorate_with ParentDecorator

  has_better_csv
  has_paper_trail
  has_tags
  # has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  scope :all, default: true
  scope('Doublons potentiels - téléphone', if: proc { !current_admin_user.caller? }) do |scope|
    scope.merge(Parent.potential_duplicates)
  end

  index do
    selectable_column
    id_column
    column :gender do |model|
      model.gender_status
    end
    column :first_name
    column :last_name
    column :children
    column :phone_number
    column :family_followed
    column :tags do |model|
      model.current_admin_user = current_admin_user
      model.tags(context: 'tags')
    end
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item *args
      end
    end
  end

  filter :gender,
    as: :check_boxes,
    collection: proc { parent_gender_select_collection }
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :is_excluded_from_workshop
  filter :family_followed, as: :check_boxes
  filter :present_on_whatsapp
  filter :follow_us_on_whatsapp
  filter :email
  filter :letterbox_name
  filter :address
  filter :postal_code
  filter :city_name
  filter :is_ambassador
  filter :terms_accepted_at
  filter :created_at
  filter :updated_at

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.object.terms_accepted_at = Time.zone.today
    f.object.family_followed = params[:family_followed] if params[:family_followed]
    f.object.address = params[:address] if params[:address]
    f.object.postal_code = params[:postal_code] if params[:postal_code]
    f.object.city_name = params[:city_name] if params[:city_name]
    f.object.letterbox_name = params[:letterbox_name] if params[:letterbox_name]
    f.object.parent2_child_ids = params[:parent2_child_ids] if params[:parent2_child_ids]
    f.object.family_followed = params[:family_followed] if params[:family_followed]
    f.object.parent2_creation = params[:parent2_creation] if params[:parent2_creation]
    f.object.created_by_us = true if f.object.new_record?

    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :parent2_creation, as: :hidden
      f.input :created_by_us, as: :hidden
      f.input :gender,
        as: :radio,
        collection: parent_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :phone_number,
        input_html: { value: f.object.decorate.phone_number }
      f.input :is_excluded_from_workshop
      f.input :family_followed
      f.input :present_on_whatsapp
      f.input :follow_us_on_whatsapp
      f.input :email
      f.input :letterbox_name
      address_input f
      f.input :is_ambassador
      f.input :job
      f.input :terms_accepted_at, as: :datepicker
      f.input :parent2_child_ids, as: :hidden, input_html: { value: f.object.parent2_child_ids.join(',') } if params[:parent2_child_ids]
      tags_input(f)
    end
    f.actions
  end

  permit_params :gender, :first_name, :last_name,
    :phone_number, :is_excluded_from_workshop, :present_on_whatsapp, :follow_us_on_whatsapp, :email,
    :letterbox_name, :address, :postal_code, :city_name,
    :is_ambassador, :job, :terms_accepted_at, :family_followed, :parent2_creation, :created_by_us,
    tags_params, parent2_child_ids: []

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab 'Infos' do
        attributes_table do
          row :gender do |decorated|
            decorated.gender_status
          end
          row :first_name
          row :last_name
          row :phone_number
          row :is_excluded_from_workshop
          row :family_followed
          row :present_on_whatsapp
          row :follow_us_on_whatsapp
          row :email do |decorated|
            decorated.email_link
          end
          row :letterbox_name
          row :address
          row :postal_code
          row :city_name
          row :created_at
          row :updated_at
          row :children
          row :is_ambassador
          row :job
          row :terms_accepted_at
          row :text_messages_count
          row :redirection_urls_count
          row :redirection_url_visits_count
          row :redirection_url_unique_visits_count
          row :redirection_unique_visit_rate
          row :redirection_visit_rate
          row :territory
          row :land
          row :mid_term_rate
          row :mid_term_reaction
          row :mid_term_speech
          row :tags do |model|
            model.current_admin_user = current_admin_user
            model.tags(context: 'tags')
          end
        end
      end
      tab 'Historique' do
        render 'admin/events/history', events: resource.events.order(occurred_at: :desc).decorate
      end
    end
  end

  action_item :manage_undelivered_books, only: :index do
    link_to 'Gestion des plis non distribués', %i[upload_undelivered_books_csv admin parents]
  end

  collection_action :upload_undelivered_books_csv, method: :get do
    render 'admin/parents/upload_undelivered_books_csv_form'
  end

  collection_action :process_csv, method: :post do
    if params[:csv_file].present?
      check_service = Parent::CheckAddressService.new(params[:csv_file]).call
      if check_service.errors.any?
        Rollbar.error('Parent::CheckAdressService', errors: check_service.errors)
        redirect_to admin_parents_path, alert: "Il y a eu des problèmes lors du traitement du fichier, contactez l'équipe tech"
      else
        redirect_to admin_parents_path, notice: 'Fichier traité avec succès!'
      end
    else
      redirect_to upload_csv_admin_your_models_path, alert: 'Erreur lors de la sélection du fichier csv des plis non livrés.'
    end
  end

  action_item :new_event, only: :show do
    dropdown_menu 'Ajouter' do
      item 'Un SMS reçu',
        new_admin_events_text_message_path(
          events_text_message: {
            related_type: resource.model.class,
            related_id: resource.id
          }
        )
      item 'Une participation aux ateliers',
        new_admin_events_workshop_participation_path(
          events_workshop_participation: {
            related_type: resource.model.class,
            related_id: resource.id
          }
        )
      item 'Une réponse à un questionnaire',
        new_admin_events_survey_response_path(
          events_survey_response: {
            related_type: resource.model.class,
            related_id: resource.id
          }
        )
      item 'Un autre événement',
        new_admin_events_other_event_path(
          events_other_event: {
            related_type: resource.model.class,
            related_id: resource.id
          }
        )
    end
  end

  batch_action :check_potential_ambassador do |ids|
    @parents = batch_action_collection.where(id: ids)
    @parents.each { |parent| parent.is_ambassador? ? next : parent.update!(is_ambassador: true) }
    redirect_to collection_path, notice: "Potentiels parents bénévoles ajoutés."
  end

  batch_action :uncheck_potential_ambassador do |ids|
    @parents = batch_action_collection.where(id: ids)
    @parents.each { |parent| !parent.is_ambassador? ? next : parent.update!(is_ambassador: false) }
    redirect_to collection_path, notice: "Potentiels parents bénévoles retirés."
  end

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :gender
    column :first_name
    column :last_name

    column :email
    column :phone_number_national
    column :present_on_whatsapp
    column :follow_us_on_whatsapp

    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

    column :territory
    column :land

    column :parent_groups

    column :job
    column :is_ambassador

    column :children_count

    column :text_messages_count

    column :redirection_urls_count
    column :redirection_url_visits_count
    column :redirection_url_unique_visits_count
    column :redirection_unique_visit_rate
    column :redirection_visit_rate

    column :terms_accepted_at

    column :tag_list

    column :created_at
    column :updated_at
  end

  controller do
    before_save do |parent|
      parent.parent2_child_ids = params[:parent][:parent2_child_ids]&.split(',')&.map(&:to_i) if params[:parent][:parent2_child_ids]
    end

    def apply_filtering(chain)
      super(chain).distinct
    end

  end
end
