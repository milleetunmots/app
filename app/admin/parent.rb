ActiveAdmin.register Parent do

  decorate_with ParentDecorator

  has_better_csv
  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

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
    column :email do |decorated|
      decorated.email_link
    end
    column :is_ambassador
    column :redirection_unique_visits
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    column :updated_at do |model|
      l model.updated_at.to_date, format: :default
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  scope :all, default: true

  filter :gender,
         as: :check_boxes,
         collection: proc { parent_gender_select_collection }
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :is_lycamobile
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
    f.inputs do
      f.input :gender,
              as: :radio,
              collection: parent_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :phone_number,
              input_html: { value: f.object.decorate.phone_number }
      f.input :is_lycamobile
      f.input :email
      f.input :letterbox_name
      f.input :address
      f.input :postal_code
      f.input :city_name
      f.input :is_ambassador
      f.input :job
      f.input :terms_accepted_at, as: :datepicker
    end
    f.actions
  end

  permit_params :gender, :first_name, :last_name,
                :phone_number, :is_lycamobile, :email,
                :letterbox_name, :address, :postal_code, :city_name,
                :is_ambassador, :job, :terms_accepted_at

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
          row :is_lycamobile
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
        end
      end
      tab 'Historique' do
        render 'admin/events/history', events: resource.events.order(occurred_at: :desc).decorate
      end
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
    column :is_lycamobile

    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

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

    column :created_at
    column :updated_at
  end

  # ---------------------------------------------------------------------------
  # DISCARD
  # ---------------------------------------------------------------------------

  use_discard

end
