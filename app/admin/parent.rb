ActiveAdmin.register Parent do

  decorate_with ParentDecorator

  has_better_csv
  has_paper_trail
  has_tags
  has_tasks
  use_discard

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
    column :tags
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
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :gender,
        as: :radio,
        collection: parent_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :phone_number,
        input_html: { value: f.object.decorate.phone_number }
      f.input :email
      f.input :letterbox_name
      address_input f
      f.input :is_ambassador
      f.input :job
      f.input :terms_accepted_at, as: :datepicker
      tags_input(f)
      family_tags_input(f)
    end
    f.actions
  end

  permit_params :gender, :first_name, :last_name,
    :phone_number, :email, :letterbox_name, :address, :postal_code, :city_name,
    :is_ambassador, :job, :terms_accepted_at,
    tags_params, family_attributes: [:id, tag_list: []]

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
          row :tags
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

  batch_action :add_family_tags do |ids|
    session[:add_tags_ids] = ids
    redirect_to action: :add_family_tags
  end

  batch_action :check_potential_ambassador do |ids|
    @parents = batch_action_collection.where(id: ids)
    @parents.each { |parent| parent.is_ambassador? ? next : parent.update!(is_ambassador: true) }
    redirect_to collection_path, notice: "Potentiels parents ambassadeurs ajoutés."
  end

  batch_action :uncheck_potential_ambassador do |ids|
    @parents = batch_action_collection.where(id: ids)
    @parents.each { |parent| !parent.is_ambassador? ? next : parent.update!(is_ambassador: false) }
    redirect_to collection_path, notice: "Potentiels parents ambassadeurs retirés."
  end

  collection_action :add_family_tags do
    @klass = Family
    @ids = session.delete(:add_tags_ids) || []
    @form_action = url_for(action: :perform_adding_family_tags)
    @back_url = request.referer
    render "active_admin/tags/add_tags"
  end

  collection_action :perform_adding_family_tags, method: :post do
    ids = params[:ids]
    tags = params[:tag_list]
    back_url = params[:back_url]

    Parent.where(id: ids).each do |object|
      object.family.tag_list.add(tags)
      object.family.save(validate: false)
    end
    redirect_to back_url, notice: "Tags ajoutés aux familles"
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

    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

    column :parent_groups

    column :job
    column :is_ambassador

    column :parent_present_on
    column :parent_follow_us_on
    column :land

    column :children_count

    column :text_messages_count
    column :text_messages_received_count
    column :text_messages_sent_count

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
    before_action :update_family_tags, only: :update

    def update_family_tags
      resource.family.update tag_list: params[:parent][:family_tag_list]
    end
  end
end
