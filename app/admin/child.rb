ActiveAdmin.register Child do

  decorate_with ChildDecorator

  has_better_csv
  has_paper_trail
  has_tasks

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :parent1, :parent2, :child_support, :group

  index do
    selectable_column
    id_column
    column :first_name do |model|
      model.admin_link(label: model.first_name)
    end
    column :last_name do |model|
      model.admin_link(label: model.last_name)
    end
    column :age, sortable: :birthdate
    column :parent1, sortable: :parent1_id
    column :parent2, sortable: :parent2_id
    column :postal_code
    column :child_support, sortable: :child_support_id do |model|
      model.child_support_status
    end
    column :group, sortable: :group_id
    column :family_redirection_unique_visits
    column :created_at do |model|
      l model.created_at.to_date, format: :default
    end
    actions do |decorated|
      discard_links(decorated.model, class: 'member_link')
    end
  end

  scope :all, default: true

  scope :without_group, group: :group
  scope :with_group, group: :group

  scope :months_between_0_and_12, group: :months
  scope :months_between_12_and_24, group: :months
  scope :months_more_than_24, group: :months

  scope :with_support, group: :support
  scope :without_support, group: :support

  scope :without_parent_to_contact, group: :parent

  filter :gender,
         as: :check_boxes,
         collection: proc { child_gender_select_collection(with_unknown: true) }
  filter :first_name
  filter :last_name
  filter :postal_code,
         as: :string
  filter :birthdate
  filter :months,
         as: :numeric,
         filters: [:equals, :gteq, :lt]
  filter :registration_source,
         as: :select,
         collection: proc { child_registration_source_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :registration_source_details,
         as: :select,
         collection: proc { child_registration_source_details_suggestions },
         input_html: { multiple: true, data: { select2: {} } }
  filter :has_quit_group
  filter :unpaused_group_id_in,
         as: :select,
         collection: proc { Group.order(:name) },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte active'
  filter :without_parent_text_message_since,
         as: :datepicker,
         required: false,
         label: 'Parent sans SMS depuis'
  filter :family_redirection_urls_count
  filter :family_redirection_url_visits_count
  filter :family_redirection_url_unique_visits_count
  filter :family_redirection_unique_visit_rate
  filter :family_redirection_unique_visits
  filter :created_at
  filter :updated_at

  batch_action :create_support, form: -> {
    {
      I18n.t('activerecord.attributes.child_support.supporter') => AdminUser.pluck(:name, :id)
    }
  } do |ids, inputs|
    batch_action_collection.find(ids).each do |child|
      next if already_existing_child_support = child.child_support
      supporter_id = inputs[I18n.t('activerecord.attributes.child_support.supporter')]
      child.create_support!(supporter_id: supporter_id)
    end
    redirect_to collection_path, notice: I18n.t('child.supports_created')
  end

  batch_action :add_to_group, form: -> {
    {
      I18n.t('activerecord.models.group') => Group.not_ended.order(:name).pluck(:name, :id)
    }
  } do |ids, inputs|
    if batch_action_collection.where(id: ids).with_group.any?
      flash[:error] = 'Certains enfants sont déjà dans une cohorte'
      redirect_to request.referer
    else
      group = Group.find(inputs[I18n.t('activerecord.models.group')])
      batch_action_collection.where(id: ids).update_all(
        group_id: group.id,
        has_quit_group: false # just in case
      )
      redirect_to request.referer, notice: 'Enfants ajoutés à la cohorte'
    end
  end

  batch_action :quit_group do |ids|
    batch_action_collection.where(id: ids).update_all(has_quit_group: true)
    redirect_to request.referer, notice: 'Modification effectuée'
  end

  batch_action :create_redirection_url, form: -> {
    {
      I18n.t('activerecord.models.redirection_target') => RedirectionTarget.order(:name).pluck(:name, :id)
    }
  } do |ids, inputs|
    children = batch_action_collection.where(id: ids)

    if children.without_parent_to_contact.any?
      flash[:error] = "Certains enfants n'ont aucun parent à contacter"
      redirect_to request.referer
    else
      redirection_target = RedirectionTarget.find(inputs[I18n.t('activerecord.models.redirection_target')])

      latest_parent1_id = nil
      children.order(:parent1_id).each do |child|
        next if latest_parent1_id == child.parent1_id
        latest_parent1_id = child.parent1_id

        if child.should_contact_parent1?
          RedirectionUrl.create!(
            redirection_target: redirection_target,
            parent_id: child.parent1_id,
            child: child
          )
        end

        if child.should_contact_parent2? && child.parent2_id
          RedirectionUrl.create!(
            redirection_target: redirection_target,
            parent_id: child.parent2_id,
            child: child
          )
        end
      end
      redirect_to redirection_target.decorate.redirection_urls_path, notice: 'URL courtes créées'
    end
  end

  batch_action :addresses_pdf do |ids|
    @children = batch_action_collection.where(id: ids).decorate
    @debug = params.key?('debug')
    render pdf: 'etiquettes',
           disposition: 'attachment',
           template: 'admin/children/addresses_pdf',
           layout: 'pdf',
           margin: {
             top: 3,
             bottom: 0,
             left: 1,
             right: 0
           },
           show_as_html: @debug,
           progress: proc { |output| puts output }
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.inputs do
      f.input :parent1,
              collection: child_parent_select_collection,
              input_html: { data: { select2: {} } }
      f.input :should_contact_parent1
      f.input :parent2,
              collection: child_parent_select_collection,
              input_html: { data: { select2: {} } }
      f.input :should_contact_parent2
      f.input :gender,
              as: :radio,
              collection: child_gender_select_collection(with_unknown: true)
      f.input :first_name
      f.input :last_name
      f.input :birthdate,
              as: :datepicker,
              datepicker_options: {
                min_date: Child.min_birthdate,
                max_date: Child.max_birthdate
              }
      f.input :registration_source,
              collection: child_registration_source_select_collection,
              input_html: { data: { select2: {} } }
      f.input :registration_source_details
      f.input :group,
              collection: child_group_select_collection,
              input_html: { data: { select2: {} } }
      f.input :has_quit_group
    end
    f.actions
  end

  permit_params :parent1_id, :parent2_id, :group_id, :has_quit_group,
                :should_contact_parent1, :should_contact_parent2,
                :gender, :first_name, :last_name, :birthdate,
                :registration_source, :registration_source_details

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

  show do
    tabs do
      tab 'Infos' do
        attributes_table do
          row :parent1
          row :should_contact_parent1
          row :parent2
          row :should_contact_parent2
          row :first_name
          row :last_name
          row :birthdate
          row :age
          row :gender do |model|
            model.gender_status
          end
          row :registration_source
          row :registration_source_details
          row :group
          row :has_quit_group
          row :family_text_messages_count
          row :family_redirection_urls_count
          row :family_redirection_url_visits_count
          row :family_redirection_url_unique_visits_count
          row :family_redirection_unique_visit_rate
          row :family_redirection_visit_rate
          row :created_at
          row :updated_at
        end
      end
      tab 'Historique' do
        render 'admin/events/history', events: resource.parent_events.order(occurred_at: :desc).decorate
      end
    end
  end

  action_item :show_support,
              only: :show,
              if: proc { resource.child_support } do
    link_to I18n.t('child.show_support_link'), [:admin, resource.child_support]
  end
  action_item :create_support,
              only: :show,
              if: proc { !resource.child_support } do
    link_to I18n.t('child.create_support_link'), [:create_support, :admin, resource]
  end
  member_action :create_support do
    if already_existing_child_support = resource.child_support
      redirect_to [:admin, already_existing_child_support], notice: I18n.t('child.support_already_existed')
    else
      resource.create_support!
      redirect_to [:edit, :admin, resource.child_support]
    end
  end
  action_item :quit_group,
              only: :show,
              if: proc { resource.group && !resource.has_quit_group? } do
    link_to 'Quitter la cohorte', [:quit_group, :admin, resource]
  end
  member_action :quit_group do
    resource.update_attribute :has_quit_group, true
    redirect_to [:admin, resource]
  end

  # ---------------------------------------------------------------------------
  # IMPORT
  # ---------------------------------------------------------------------------

  action_item :new_import,
              only: :index do
    link_to I18n.t('child.new_import_link'), [:new_import, :admin, :children]
  end
  collection_action :new_import do
    @import_action = perform_import_admin_children_path
  end
  collection_action :perform_import, method: :post do
    @csv_file = params[:import][:csv_file]

    service = ChildrenImportService.new(csv_file: @csv_file).call

    if service.errors.empty?
      redirect_to admin_children_path, notice: 'Import terminé'
    else
      @import_action = perform_import_admin_children_path
      @errors = service.errors
      render :new_import
    end
  end

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id

    column :first_name
    column :last_name
    column :birthdate
    column :age
    column :gender
    column :letterbox_name
    column :address
    column :city_name
    column :postal_code

    column :parent1_gender
    column :parent1_first_name
    column :parent1_last_name
    column :parent1_email
    column :parent1_phone_number_national
    column :parent1_is_lycamobile
    column :should_contact_parent1

    column :parent2_gender
    column :parent2_first_name
    column :parent2_last_name
    column :parent2_email
    column :parent2_phone_number_national
    column :parent2_is_lycamobile
    column :should_contact_parent2

    column :registration_source
    column :registration_source_details

    column :group_name
    column :has_quit_group

    column :family_text_messages_count

    column :family_redirection_urls_count
    column :family_redirection_url_visits_count
    column :family_redirection_url_unique_visits_count
    column :family_redirection_unique_visit_rate
    column :family_redirection_visit_rate

    column :created_at
    column :updated_at
  end

  controller do
    def csv_filename
      filter_name = params.fetch(:q, {}).fetch(:unpaused_group_id_in, []).map do |group_id|
        Group.find_by_id(group_id)&.name
      end.join(',')

      [
        collection.object.klass.model_name.human.pluralize,
        current_scope.name,
        filter_name.presence,
        Time.zone.now.to_date.to_s(:default)
      ].compact.join(' - ') + '.csv'
    end
  end

  # ---------------------------------------------------------------------------
  # DISCARD
  # ---------------------------------------------------------------------------

  use_discard

end
