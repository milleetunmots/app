ActiveAdmin.register Workshop do
  decorate_with WorkshopDecorator

  has_better_csv
  use_discard

  includes :animator, :parents

  before_action :format_parent_ids, only: :create
  after_create do |workshop|
    flash[:error] = "Aucune invitation n'a pu être envoyée. Prévenez le pôle technique" if workshop.workshop_participations.empty?
  end

  index do
    selectable_column
    id_column
    column :name
    column :display_topic
    column :animator
    column :co_animator
    column :workshop_date
    column :workshop_address
    column :location
    column :workshop_land
    column :canceled
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item(*args)
      end
    end
  end

  filter :name
  filter :animator
  filter :address
  filter :postal_code
  filter :city_name
  filter :location
  filter :canceled

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :topic, collection: workshop_topic_select_collection, input_html: { data: { select2: {} } }
      f.input :workshop_date, as: :datepicker
      f.input :animator, input_html: { data: { select2: {} } }
      f.input :co_animator
      address_input f
      f.input :location
      f.input :parent_selection,
              as: :select,
              input_html: {
                id: 'workshop-parent-select',
                data: {
                  url: search_eligible_parents_admin_workshops_path,
                  multiple: true
                },
                disabled: !object.new_record?
              }

      f.input :parent_ids, as: :hidden
      f.input :workshop_land, collection: Child::LANDS.sort, input_html: { data: { select2: {} }, disabled: !object.new_record? }
      f.input :invitation_message, input_html: { rows: 5, disabled: !object.new_record? }
      f.input :canceled
    end
    f.actions
  end

  permit_params :topic, :workshop_date, :animator_id, :co_animator, :address, :postal_code, :city_name,
                :invitation_message, :workshop_land, :location, :canceled, tags_params, parent_ids: []

  show do
    tabs do
      tab 'Infos' do
        attributes_table do
          row :name
          row :display_topic
          row :workshop_date
          row :animator
          row :co_animator
          row :workshop_address
          row :location
          row :invitation_message
          row :parents_who_accepted
          row :parents_who_refused
          row :parent_invited_number
          row :parent_who_accepted_number
          row :parent_who_refused_number
          row :parent_who_ignored_number
          row :workshop_land
          row :canceled
        end
      end
    end
  end

  csv do
    column :id
    column :name
    column :display_topic
    column :animator_csv
    column :co_animator
    column :workshop_date
    column :workshop_address
    column :location
    column :workshop_land
    column :workshop_participants_csv
    column :parents_who_accepted_csv
    column :parents_who_refused_csv
    column :parents_without_response_csv
    column :canceled
  end

  action_item :update_parents_presence, only: :show do
    link_to 'Indiquer la présence des parents', [:update_parents_presence, :admin, resource]
  end

  collection_action :search_eligible_parents, method: :get

  member_action :update_parents_presence do
    @values = resource.workshop_participations.where(parent_response: 'Oui').to_a
    @perform_action = perform_update_parents_presence_admin_workshop_path
  end

  member_action :perform_update_parents_presence, method: :post do
    params[:presence].each do |parent_id, presence|
      resource.workshop_participations.find_by(related_id: parent_id).update(parent_presence: presence)
    end
    redirect_to admin_workshop_path, notice: 'Présences indiquées'
  end

  action_item :register_parents, only: :show do
    link_to 'Inscrire des parents', [:register_parents, :admin, resource]
  end

  member_action :register_parents do
    @workshop_id = resource.id
    @perform_action = perform_parents_registration_admin_workshop_path
  end

  member_action :perform_parents_registration, method: :post do
    workshop = Workshop.find(params[:workshop_id])
    parent_to_register_ids = params[:workshop][:parent_ids].reject(&:blank?)
    parents_to_register = Parent.not_excluded_from_workshop.where(id: parent_to_register_ids)
    workshop.parents << parents_to_register

    parents_to_register.each do |parent|
      event = Event.find_by(related: parent, workshop: workshop)
      if event
        event.parent_response == 'Oui' ? next : event.update!(parent_response: 'Oui', acceptation_date: Time.zone.today)
      else
        Event.create(
          type: 'Events::WorkshopParticipation',
          related: parent,
          body: workshop.name,
          occurred_at: workshop.workshop_date,
          workshop: workshop,
          parent_response: 'Oui',
          acceptation_date: Time.zone.today
        )
      end
    end

    redirect_to admin_workshop_path, notice: 'Parent(s) inscrit(s)'
  end

  controller do
    def format_parent_ids
      params[:workshop][:parent_ids] = params[:workshop][:parent_ids].split(',').map(&:to_i) if params[:workshop][:parent_ids].present?
    end

    def search_eligible_parents
      term = params[:term]
      parents = Parent.not_excluded_from_workshop.where('unaccent(first_name) ILIKE unaccent(?) OR unaccent(last_name) ILIKE unaccent(?)', "%#{term}%", "%#{term}%")
                      .order(:first_name, :last_name)
                      .decorate
                      .map do |result|
                        {
                          id: result.id,
                          text: result.name
                        }
                      end
      render json: {
        results: parents
      }
    end
  end
end
