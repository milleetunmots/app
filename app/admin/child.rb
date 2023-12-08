ActiveAdmin.register Child do
  decorate_with ChildDecorator

  has_better_csv
  has_paper_trail
  has_tags
  has_tasks
  use_discard

  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  includes :parent1, :parent2, :child_support, :group

  index do
    div do
      render 'index_top'
    end

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
    column :territory
    column :child_support, sortable: :child_support_id, &:child_support_status
    column :group, sortable: :group_id
    column :group_status
    column :source
    column :tags do |model|
      model.tags(context: 'tags')
    end
    column :land
    column :selected_support_module_list
    actions dropdown: true do |decorated|
      discard_links_args(decorated.model).each do |args|
        item(*args)
      end
    end
  end

  scope :all, default: true

  scope :active_group, group: :group
  scope :without_group, group: :group

  scope :months_between_0_and_12, group: :months
  scope :months_between_12_and_24, group: :months
  scope :months_more_than_24, group: :months

  scope :without_parent_to_contact, group: :parent

  scope :available_for_the_workshops, group: :workshop

  scope :only_siblings, group: :siblings
  scope('Doublons potentiels', if: proc { !current_admin_user.caller? }) do |scope|
    scope.merge(Child.potential_duplicates)
  end

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
         filters: %i[equals gteq lt]
  filter :source_id_in,
          as: :select,
          collection: proc { source_select_collection },
          input_html: { multiple: true, data: { select2: {} } },
          label: "Source d'inscription"
  filter :source_channel_in,
          as: :select,
          collection: proc { source_channel_select_collection },
          input_html: { multiple: true, data: { select2: {} } },
          label: "Canal d'inscription"
  filter :source_details_matches_any,
          as: :select,
          collection: proc { source_details_suggestions },
          input_html: { multiple: true, data: { select2: {} } },
          label: "Précisions sur l'origine"
  filter :supporter_id_in,
          as: :select,
          collection: proc { child_supporter_select_collection },
          input_html: { multiple: true, data: { select2: {} } },
          label: 'Responsable'
  filter :group_id_in,
         as: :select,
         collection: proc { child_group_select_collection },
         input_html: { multiple: true, data: { select2: {} } },
         label: 'Cohorte'
  filter :group_status,
         as: :select,
         collection: proc { child_group_status_select_collection },
         input_html: { multiple: true, data: { select2: {} } }
  filter :group_start,
         as: :datepicker,
         required: false,
         label: "Début de l'accompagnement"
  filter :group_end,
         as: :datepicker,
         required: false,
         label: "Fin de l'accompagnement"
  filter :active_group_id_in,
         as: :select,
         collection: proc { child_group_select_collection },
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
  filter :src_url
  filter :created_at
  filter :updated_at

  batch_action :create_support do |ids|
    batch_action_collection.find(ids).each do |child|
      next if child.child_support

      child.create_support!
    end
    redirect_to collection_path, notice: I18n.t('child.supports_created')
  end

  batch_action :add_to_group, form: -> {
    {
      I18n.t('activerecord.models.group') => Group.not_started.order(:name).pluck(:name, :id)
    }
  } do |ids, inputs|
    if batch_action_collection.where(id: ids).with_ongoing_group.any?
      flash[:error] = 'Certains enfants sont dans une cohorte déjà lancée'
      redirect_to request.referer
    else
      group = Group.find(inputs[I18n.t('activerecord.models.group')])
      batch_action_collection.where(id: ids).update_all(
        group_id: group.id,
        group_status: 'active',
        group_start: group.started_at
      )

      Child.where(id: ids).parents.each do |parent|
        parent.update family_followed: true
      end

      redirect_to request.referer, notice: 'Enfants ajoutés à la cohorte'
    end
  end

  batch_action :quit_group do |ids|
    if batch_action_collection.where(id: ids).with_stopped_group.any?
      flash[:error] = 'Certains enfants sont déjà dans une cohorte arrêtée'
      redirect_to request.referer
    end
    batch_action_collection.where(id: ids).update_all(group_status: 'paused')
    redirect_to request.referer, notice: 'Modification effectuée'
  end

  batch_action :reactive_group do |ids|
    if batch_action_collection.where(id: ids).with_stopped_group.any?
      flash[:error] = 'Certains enfants sont déjà dans une cohorte arrêtée'
      redirect_to request.referer
    else
      batch_action_collection.where(id: ids).update_all(group_status: 'active')
      redirect_to request.referer, notice: 'Modification effectuée'
    end
  end

  batch_action :create_redirection_url, form: -> {
    {
      I18n.t('activerecord.models.medium') => Medium.for_redirections.order(:name).kept.pluck(:name, :id)
    }
  } do |ids, inputs|
    children = batch_action_collection.where(id: ids)

    if children.without_parent_to_contact.any?
      flash[:error] = "Certains enfants n'ont aucun parent à contacter"
      redirect_to request.referer
    else
      medium = Medium.find(inputs[I18n.t('activerecord.models.medium')])

      redirection_target = RedirectionTarget.where(medium: medium).first_or_create!

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

        next unless child.should_contact_parent2? && child.parent2_id

        RedirectionUrl.create!(
          redirection_target: redirection_target,
          parent_id: child.parent2_id,
          child: child
        )
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
           disable_local_file_access: false,
           enable_local_file_access: true,
           progress: proc { |output| puts output }
  end

  batch_action :generate_quit_sms do |ids|
    ids.reject! do |id|
      child = Child.find(id)

      child.child_support&.will_stay_in_group || child.group_status != 'active'
    end

    @children = batch_action_collection.where(id: ids)

    if ids.empty?
      flash[:error] = "Ces enfants sont déjà indiqués comme voulant poursuivre l'accompagnement ou ne sont pas actifs dans la cohorte"
      redirect_to request.referer
    elsif @children.without_parent_to_contact.any?
      flash[:error] = "Certains enfants n'ont aucun parent à contacter"
      redirect_to request.referer
    elsif @children.with_stopped_group.any?
      flash[:error] = 'Certains enfants sont déjà dans une cohorte arrêtée'
      redirect_to request.referer
    else
      next_saturday = Date.today.next_occurring(:saturday)
      hour = Time.parse('14:30').strftime('%H:%M')
      recipients = ids.map { |id| "child.#{id}" }
      message = 'Bonjour ! Ca fait 4 mois que je vous envoie des SMS pour votre enfant. Bravo pour tout ce que vous faites pour lui :) Voulez vous continuer à recevoir ces SMS et livres ? Cliquez sur le lien ci-dessous et répondez OUI ! Ca reprendra prochainement ! Je vous souhaite de beaux moments avec vos enfants :) {QUIT_LINK}'

      service = Child::ProgramQuitMessageService.new(
        next_saturday,
        hour,
        recipients,
        message,
        nil,
        nil,
        true,
        nil
      ).call

      @children.update_all(group_status: 'paused')

      if service.errors.any?
        flash[:alert] = service.errors
        redirect_back(fallback_location: root_path)
      else
        flash[:notice] = 'Message de continuation envoyé'
        redirect_to admin_sent_by_app_text_messages_url
      end
    end
  end

  batch_action :excel_export do |ids|
    children = batch_action_collection.where(id: ids)
    if children.with_stopped_group.any?
      flash[:error] = 'Certains enfants sont dans une cohorte arrêtée'
      redirect_to request.referer
    else
      service = Child::ExportBookExcelService.new(children: children).call

      send_data(service.workbook.read_string, filename: "#{Date.today.strftime('%d-%m-%Y')}.xlsx")
    end
  end

  # ---------------------------------------------------------------------------
  # FORM
  # ---------------------------------------------------------------------------

  form do |f|
    f.semantic_errors(*f.object.errors.keys)
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
              collection: child_gender_select_collection
      f.input :first_name
      f.input :last_name
      f.input :birthdate,
              as: :datepicker,
              datepicker_options: {
                min_date: Child.min_birthdate,
                max_date: Child.max_birthdate
              }
      f.input :available_for_workshops
      f.semantic_fields_for :children_source do |children_source_f|
        children_source_f.input :source,
                                as: :select,
                                collection: source_select_collection
        children_source_f.input :details
      end
      f.input :group,
              collection: child_group_select_collection,
              input_html: { data: { select2: {} } }
      f.input :group_status,
              collection: child_group_status_select_collection,
              input_html: { data: { select2: {} } }
      tags_input(f)
    end
    f.actions
  end

  permit_params :parent1_id, :parent2_id, :group_id,
                :should_contact_parent1, :should_contact_parent2,
                :gender, :first_name, :last_name, :birthdate, :available_for_workshops, :group_status,
                tags_params.merge(children_source: [:source, :details])

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
          row :gender, &:gender_status
          row :source
          row :source_details
          row :territory
          row :land
          row :available_for_workshops
          row :group
          row :group_status
          row :group_start
          row :group_end
          row :child_group_months
          row :months_between_registration_and_group_start
          row :months_since_group_start
          row :family_text_messages_count
          row :family_redirection_urls_count
          row :family_redirection_url_visits_count
          row :family_redirection_url_unique_visits_count
          row :family_redirection_unique_visit_rate
          row :family_redirection_visit_rate
          row :security_code, &:security_code
          row :public_edit_url do |decorated|
            decorated.public_edit_link(target: '_blank')
          end
          row :available_for_workshops
          row :selected_support_module_list
          row :tags do |model|
            model.tags(context: 'tags')
          end
          row :src_url
          row :created_at
          row :updated_at
        end
      end
      tab 'Historique' do
        render 'admin/events/history',
               events: resource.parent_events.order(occurred_at: :desc).decorate
      end
    end
  end

  action_item :show_support, only: :show, if: proc { resource.child_support } do
    link_to I18n.t('child.show_support_link'), [:admin, resource.child_support]
  end

  action_item :create_support, only: :show, if: proc { !resource.child_support } do
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
              if: proc { resource.group && %w(paused active).include?(resource.model.group_status) } do
    link_to 'Quitter la cohorte', [:quit_group, :admin, resource]
  end
  member_action :quit_group do
    resource.update_attribute :group_status, 'stopped'
    resource.update_attribute :group_end, resource.model.group.ended_at&.past? ? resource.model.group.ended_at : Time.now
    redirect_to [:admin, resource]
  end

  # ---------------------------------------------------------------------------
  # TOOLS
  # ---------------------------------------------------------------------------

  action_item :tools, only: :index do
    dropdown_menu 'Outils' do
      item "Télécharger les listes d'enfants par cohorte au format Excel V1",
           %i[download_book_files_v1 admin children]
      item "Télécharger les listes d'enfants par module au format Excel V2",
           %i[download_book_files_v2 admin children]
    end
  end

  collection_action :download_book_files_v1 do
    service = Child::ExportBooksV1Service.new.call

    if service.errors.empty?
      send_file service.zip_file.path, type: 'application/zip', x_sendfile: true,
                                       disposition: 'attachment', filename: "#{Date.today.strftime('%d-%m-%Y')}.zip"
    else
      flash[:alert] = service.errors
      redirect_back(fallback_location: root_path)
    end
  end

  collection_action :download_book_files_v2 do
    service = Child::ExportBooksV2Service.new.call

    if service.errors.empty?
      send_file service.zip_file.path, type: 'application/zip', x_sendfile: true,
                                       disposition: 'attachment', filename: "#{Date.today.strftime('%d-%m-%Y')}.zip"
    else
      flash[:alert] = service.errors
      redirect_back(fallback_location: root_path)
    end
  end

  action_item :view do
    link_to 'Nouveau parent', new_admin_parent_path, target: '_blank'
  end

  # ---------------------------------------------------------------------------
  # CSV EXPORT
  # ---------------------------------------------------------------------------

  csv do
    column :id
    column :child_support_id

    column :first_name
    column :last_name
    column :birthdate
    column :registration_months_range
    column :age
    column :gender
    column :letterbox_name
    column :address
    column :city_name
    column :postal_code
    column :territory
    column :land

    column :child_group_name
    column :child_group_months
    column :months_between_registration_and_group_start
    column :months_since_group_start

    column :parent1_gender
    column :parent1_first_name
    column :parent1_last_name
    column :parent1_email
    column :parent1_phone_number_national
    column :parent1_present_on_facebook
    column :parent1_follow_us_on_facebook
    column :parent1_present_on_whatsapp
    column :parent1_follow_us_on_whatsapp
    column :should_contact_parent1

    column :parent2_gender
    column :parent2_first_name
    column :parent2_last_name
    column :parent2_email
    column :parent2_phone_number_national
    column :parent2_present_on_facebook
    column :parent2_follow_us_on_facebook
    column :parent2_present_on_whatsapp
    column :parent2_follow_us_on_whatsapp
    column :should_contact_parent2

    column :group_status

    column :family_text_messages_count
    column :family_text_messages_received_count
    column :family_text_messages_sent_count

    column :family_redirection_urls_count
    column :family_redirection_url_visits_count
    column :family_redirection_url_unique_visits_count
    column :family_redirection_unique_visit_rate
    column :family_redirection_visit_rate

    column :tag_list

    column :created_at
    column :updated_at
  end

  controller do
    after_save do |child|
      next if child.errors.any?

      if child.group && %w(active stopped paused).include?(child.group_status) && child.group_start.nil?
        child.update!(group_start: child.group.started_at)
        child.parent1&.update family_followed: true
        child.parent2&.update family_followed: true
      end
      child.update!(group_end: child.group.ended_at, group_status: 'stopped') if child.group&.ended_at&.past?
    end

    def csv_filename
      filter_name = params.fetch(:q, {}).fetch(:active_group_id_in, []).map do |group_id|
        Group.find_by_id(group_id)&.name
      end.join(',')

      [
        Child.model_name.human.pluralize,
        current_scope.name,
        filter_name.presence,
        Time.zone.now.to_date.to_s(:default)
      ].compact.join(' - ') + '.csv'
    end
  end
end
